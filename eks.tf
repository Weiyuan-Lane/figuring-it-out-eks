module "eks_sg" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 18.0"

  cluster_name                    = "${local.sg_namespace}-cluster"
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id = module.vpc_sg.vpc_id
  subnet_ids = module.vpc_sg.private_subnets

  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t4g.medium"
    # update_launch_template_default_version = true
    iam_role_additional_policies           = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  self_managed_node_groups = {
    memory_config_one = {
      name = "memory_config_one"

      public_ip     = true
      max_size      = 5
      desired_size  = 1
      instance_type = "t3.medium"
      ami_id        = local.sg_ami_id

      pre_bootstrap_user_data = <<-EOT
      echo "foo"
      export FOO=bar
      EOT

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      post_bootstrap_user_data = <<-EOT
      cd /tmp
      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
      sudo systemctl enable amazon-ssm-agent
      sudo systemctl start amazon-ssm-agent
      EOT
    }
  }

  providers = {
    aws = aws.sg
  }
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

resource "null_resource" "apply" {
  triggers = {
    kubeconfig_sg = base64encode(local.kubeconfig_sg)
    cmd_patch_sg_cluster  = <<-EOT
      kubectl create configmap aws-auth -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl patch configmap/aws-auth --patch "${module.eks_sg.aws_auth_configmap_yaml}" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
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
