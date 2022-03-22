# Figuring It Out - Kubernetes, EKS, AWS

## Full setup instructions (across all of the guides)

- [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | Run `terraform init`
- [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | Run `AWS_PROFILE=*profile_name* terraform apply`
- [From 2.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/2.0.0) | Run `./bringup.sh`

---

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

## #2 - Interacting with your cluster? Web dashboards? Terminal? - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-2-interacting-with-your-cluster-a70328e612b8)

#### Viewing Kubernetes Dashboard

1. Run the following command
```shell
kubectl proxy --port=8001
```

2. Get your token with the following command

You can get your token with the following command, copy the token in the returned JSON:
```shell
aws eks get-token --cluster-name *cluster_name* --profile *named_profile*
```

(Alternative) For MacOS, if you have `jq` installed, the following command should automatically copy the token:
```
aws eks get-token --cluster-name *cluster_name* --profile *named_profile* | jq -r .status.token | pbcopy
```

3. Open the dashboard from [this link](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:443/proxy/)

4. Use the token from step 2 to log in
