module "eks_sg" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 18.0"

  cluster_name                    = local.cluster_sg_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.vpc_sg.vpc_id
  subnet_ids = module.vpc_sg.private_subnets

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t4g.medium"
    iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  self_managed_node_groups = {
    memory_config_one = {
      name = "memory_config_one"

      public_ip     = false
      max_size      = 5
      desired_size  = 1
      instance_type = "t3.medium"
      ami_id        = local.sg_ami_id

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      post_bootstrap_user_data = <<-EOT
      cd /tmp
      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      EOT

      tags = {
        "k8s.io/cluster-autoscaler/node-template/autoscaling-options/scaledownutilizationthreshold": local.sg_memory_config_one_scale_down_cpu_threshold,
        "k8s.io/cluster-autoscaler/node-template/autoscaling-options/scaledownunneededtime": local.sg_memory_config_one_scale_backoff_time,
      }
    }
  }

  # Needed for Kubernetes dashboard
  # See examples in module here: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/node_groups.tf#L61
  node_security_group_additional_rules = {
    ingress_self_kubernetes_dashboard_port = {
      description                   = "Cluster API to node groups (Kubernetes Dashboard port only)"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }

    ingress_self_coredns_metrics_server_port = {
      description = "Node to node CoreDNS (metrics server - port 10250)"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "ingress"
      self        = true
    }

    egress_self_coredns_metrics_server_port = {
      description = "Node to node CoreDNS (metrics server - port 10250)"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "egress"
      self        = true
    }
  }

  providers = {
    aws = aws.sg
  }
}

# Autoscaling policy for "memory_config_one"
resource "aws_autoscaling_policy" "aws_autoscaling_eks_sg_memory_config_one" {
  # Ensure to reference right autoscaling group name
  autoscaling_group_name    = module.eks_sg.self_managed_node_groups.memory_config_one.autoscaling_group_name
  name                      = "aws_autoscaling_eks_${local.sg_memory_config_one}"
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = local.sg_memory_config_one_scale_up_cpu_percent
  }

  provider = aws.sg
}

################################################################################
# aws-auth configmap
# Only EKS managed node groups automatically add roles to aws-auth configmap
# so we need to ensure fargate profiles and self-managed node roles are added
################################################################################

data "aws_eks_cluster_auth" "sg_cluster" {
  name = module.eks_sg.cluster_id
}

locals {
  kubeconfig_sg = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks_sg.cluster_id
      cluster = {
        certificate-authority-data = module.eks_sg.cluster_certificate_authority_data
        server                     = module.eks_sg.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks_sg.cluster_id
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.sg_cluster.token
      }
    }]
  })
}

################################################################################
# Embedding our intended roles to the above config-map yaml
# 
# Supported roles:
#   - Backend
#   - DevOps
################################################################################

# Role settings across all clusters
locals {
  aws_devops_roles_and_bindings = templatefile("resources/roles/devops_role.yaml.tmpl", 
    {
      role_username = local.eks_devops_username
    }
  )

  aws_backend_roles_and_bindings = templatefile("resources/roles/backend_role.yaml.tmpl", 
    {
      role_username = local.eks_backend_username
    }
  )
}

# Embedded "mapRoles" for sg cluster only. 
# Repeat for other clusters in the future
locals {
  eks_sg_full_role_configmap_yaml = yamlencode({
    data = {
      mapRoles = yamlencode(concat(
        yamldecode(yamldecode(module.eks_sg.aws_auth_configmap_yaml).data.mapRoles),
        [
          {
            rolearn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_devops_role}"
            username  = "${local.eks_devops_username}"
          },
          {
            rolearn   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_backend_role}"
            username  = "${local.eks_backend_username}"
          }
        ]
      ))
    }
  })
}

################################################################################
# Run all kubectl imperative commands declaratively to achieve desired state
################################################################################

resource "null_resource" "sg_cluster_apply" {
  triggers = {
    kubeconfig_sg = base64encode(local.kubeconfig_sg)

    cmd_patch_sg_cluster  = <<-EOT
      kubectl create configmap aws-auth -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl patch configmap/aws-auth --patch "${local.eks_sg_full_role_configmap_yaml}" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)

      # Create namespaces
      echo "${local.namespaces_yaml}" | kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f -

      # Apply intended roles
      echo "${local.aws_devops_roles_and_bindings}" | kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f -
      echo "${local.aws_backend_roles_and_bindings}" | kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f -
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig_sg
    }
    command = self.triggers.cmd_patch_sg_cluster
  }
}
