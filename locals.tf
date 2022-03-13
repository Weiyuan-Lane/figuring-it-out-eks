locals {
  sg_namespace  = "tech-sg"
  sg_region     = "ap-southeast-1"

  # Run 'aws ec2 describe-images --region ap-southeast-1 --filters "Name=name,Values=amazon-eks-node-1.21-v*"'
  # to get the list of AMI ids applicable for EKS of this version
  sg_ami_id     = "ami-0af8f071b9674610d"
}

locals {
  cluster_version = "1.21"
  cluster_sg_name = "${local.sg_namespace}-eks-${random_string.sg_suffix.result}"
}

resource "random_string" "sg_suffix" {
  length  = 8
  special = false
}
