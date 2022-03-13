# Figuring It Out - Kubernetes, EKS, AWS

## #1 - Getting Started - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-1-getting-started-1132b20ae0f8)

#### AWS CLI
- Make sure that you have installed the AWS CLI - [Instructions](https://aws.amazon.com/cli/)
- Configure the CLI to your account credentials - [Instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds)

#### Terraform CLI
- Install the CLI here - [Instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)

--- 

To apply the changes from the Terraform configuration, simply run the following command ( with or without the `AWS_PROFILE` variable depending on your use of named profiles):
```
AWS_PROFILE=*profile_name* terraform apply
```
