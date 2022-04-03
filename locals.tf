
################################################################################
# SG cluster exclusive values
################################################################################
locals {
  sg_namespace          = "tech-sg"
  sg_region             = "ap-southeast-1"
  sg_memory_config_one  = "sg_memory_config_one"

  # Run 'aws ec2 describe-images --region ap-southeast-1 --filters "Name=name,Values=amazon-eks-node-1.21-v*"'
  # to get the list of AMI ids applicable for EKS of this version
  sg_ami_id     = "ami-0af8f071b9674610d"

  # Controlling sg cluster "memory_config_one" scaling params
  sg_memory_config_one_scale_up_cpu_percent     = 90.0
  sg_memory_config_one_scale_down_cpu_threshold = "0.5"
  sg_memory_config_one_scale_backoff_time       = "1m0s"
}

################################################################################
# Global values (shared across all clusters)
################################################################################

locals {
  namespaces_yaml = templatefile("resources/namespaces.yaml", {}) 
}

locals {
  # Make sure to use only the available versions here: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
  cluster_version = "1.21"
  cluster_sg_name = "${local.sg_namespace}-cluster"
}


# Role and group naming
locals {
  eks_devops_group         = "eks_devops_group"
  eks_devops_group_policy  = "eks_devops_group_policy"
  eks_devops_role          = "EksDevopsRole"
  eks_devops_username      = "devops-user"

  eks_backend_group         = "eks_backend_group"
  eks_backend_group_policy  = "eks_backend_group_policy"
  eks_backend_role          = "EksBackendRole"
  eks_backend_username      = "backend-user"
}