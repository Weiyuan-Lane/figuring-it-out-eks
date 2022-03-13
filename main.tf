terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }
  }

  required_version = ">= 1.1.6"
}

# Default region as "us-east-1"
# To differ from initial region to ensure that settings are tested
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias = "sg"
  region = local.sg_region
}

