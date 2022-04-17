# Figuring It Out - Kubernetes, EKS, AWS

## Full setup instructions (across all of the guides)

Make sure you set up the `Installation dependencies` first, before moving on to the `Deployment dependencies`.
### Installation dependencies
1. AWS CLI - Make sure that you have installed the AWS CLI - [Instructions](https://aws.amazon.com/cli/)
2. AWS CLI - Configure the AWS CLI to your account credentials - [Instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds)
3. Terraform CLI - Install the Terraform CLI here - [Instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)
4. Helm - Install Helm - [Instructions](https://helm.sh/docs/intro/install/)

### Deployment instructions
1. [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | Configure [locals.tf](https://github.com/Weiyuan-Lane/figuring-it-out-eks/blob/main/locals.tf) and [variables.tf](https://github.com/Weiyuan-Lane/figuring-it-out-eks/blob/main/variables.tf) to your desired values
2. [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | (Only for first time) Run `terraform init`
3. [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | Run `AWS_PROFILE=*named_profile* terraform apply`
4. [From 1.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/1.0.0) | Run `aws eks get-token --cluster-name *cluster_name* --profile *named_profile*`
5. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Run `./components.sh bringup`
6. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Check for Ingress-Nginx NLB DNS name after deployed 
7. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Configure [dns-terraform-module/locals.tf](https://github.com/Weiyuan-Lane/figuring-it-out-eks/blob/main/dns-terraform-module/locals.tf) by adding the DNS name of your NLB above into it. Make other necessary changes too.
8. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | (Only for first time) Run `terraform -chdir=dns-terraform-module init`
9. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Run `AWS_PROFILE=*named_profile* terraform -chdir=dns-terraform-module apply`
10. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Apply custom DNS settings if not on Route 53. See [here](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-4-all-about-ingress-be59d651f11d) for more infomation.

### Bringdown instructions
1. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Run `AWS_PROFILE=*named_profile* terraform -chdir=dns-terraform-module destroy`
2. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Run `./components.sh bringdown`
2. [From 4.0.0](https://github.com/Weiyuan-Lane/figuring-it-out-eks/releases/tag/4.0.0) | Run `AWS_PROFILE=*named_profile* terraform destroy`

---

## #1 - Getting Started - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-1-getting-started-1132b20ae0f8)


To apply the changes from the Terraform configuration, simply run the following command ( with or without the `AWS_PROFILE` variable depending on your use of named profiles):
```
AWS_PROFILE=*profile_name* terraform apply
```

---

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

---
## #3 - Role-Based Access Control (RBAC) - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-3-rbac-701ea68ecc9c)

#### Testing out RBAC

In the following, we will test our backend role with a random user name `SampleBackendUser`. This user will be assign to our group AWS IAM `eks_backend_group` (found in `locals.tf`), which is linked to the `EksBackendRole` Role in our Kubernetes cluster in EKS.

Do change the `SampleBackendUser`, `EksBackendRole`, and `eks_backend_group` values if you wish to test out other roles (like devops) or the ones that you create yourself.

1. Create a backend user with the following command
```
aws iam create-user --user-name SampleBackendUser --profile *aws_profile*
```

2. Add the user to the backend group on AWS IAM
```
aws iam add-user-to-group --group-name eks_backend_group --user-name SampleBackendUser --profile *aws_profile*
```

3. Verify that `SampleBackendUser` has been assigned to the AWS IAM group by checking the output of the following command
```
aws iam get-group --group-name eks_backend_group --profile *aws_profile*
```

4. Create the access key for this backend user
```
aws iam create-access-key --user-name SampleBackendUser --profile *aws_profile* | tee /tmp/SampleBackendUser.json
```

5. Run the following script, and append the `echo` output to `~/.aws/credentials` (replace previous test account if there are)
```
######## For AWS Config: ~/.aws/credentials
AWS_USER="SampleBackendUser"
AWS_ROLE="EksBackendRole"
AWS_FILE_PATH="/tmp/$AWS_USER.json"
echo "\n[$AWS_USER]\naws_access_key_id=$(jq -r .AccessKey.AccessKeyId $AWS_FILE_PATH)\naws_secret_access_key=$(jq -r .AccessKey.SecretAccessKey $AWS_FILE_PATH)"
```

6. Run the following script, and append the `echo` output to `~/.aws/config` (again, replace previous test account if there are)
```
######## For AWS Config: ~/.aws/config
AWS_USER="SampleBackendUser"
AWS_ROLE="EksBackendRole"
AWS_FILE_PATH="/tmp/$AWS_USER.json"
ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text --profile $AWS_USER`
echo "\n[profile $AWS_ROLE]\nrole_arn=arn:aws:iam::${ACCOUNT_ID}:role/$AWS_ROLE\nsource_profile=$AWS_USER"
```

7. Update your cluster credentials as the new backend user account with the following command, before testing out access control with `Kubernetes Dashboard` or `k9s`
```
aws eks --region *region* update-kubeconfig --name *cluster_name* --profile EksBackendRole
```

8. Test your user access control with the following 2 commands. Note that the backend's role can be verified from [backend_role.yaml.tmpl](https://github.com/Weiyuan-Lane/figuring-it-out-eks/tree/3.0.0/resources/roles/backend_role.yaml.tmpl). The first command should return a `no`, while the second command should return a `yes`.

`kubectl auth can-i get secret -n production` and
`kubectl auth can-i get secret -n development`


9. (Cleanup) Once you are done with your testing, make sure you cleanup and delete the user with the following commands
```
aws iam remove-user-from-group --group-name eks_backend_group --user-name SampleBackendUser --profile *aws_profile*
aws iam delete-access-key --user-name SampleBackendUser --access-key-id `jq -r '.AccessKey.AccessKeyId' /tmp/SampleBackendUser.json` --profile *aws_profile*
aws iam delete-user --user-name SampleBackendUser --profile *aws_profile*
```

---
#### Setting up AWS profile for assuming user easily

Following the steps above from testing, we can also reapply some of the same steps to make it easier for our team members to access our Kubernetes clusters. `YourUserProfile` will be the user's local AWS profile (if not set, likely it should be `default`), and `YourIntendedAWSRoleForUser` is the AWS IAM role assigned to your team member, feel free to change these two values to your intended values in the following steps

The following steps assume that your team members have already set up their AWS cli. If it is not yet done, visit [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) to find out how to do it.

1. Run the following and add the `echo` output to `~/.aws/config`
```
######## For AWS Config: ~/.aws/config
AWS_MAIN_PROFILE="YourUserProfile"
AWS_ROLE="YourIntendedAWSRoleForUser"
ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text --profile $AWS_MAIN_PROFILE`
echo "\n[profile $AWS_ROLE]\nrole_arn=arn:aws:iam::${ACCOUNT_ID}:role/$AWS_ROLE\nsource_profile=$AWS_MAIN_PROFILE"
```

2. Update your team member's cluster credentials with the following command:
```
aws eks --region *region* update-kubeconfig --name *cluster_name* --profile YourIntendedAWSRoleForUser
```

And your team member should have the cluster set up! Note that the above new profile `YourIntendedAWSRoleForUser` can also be used to generate the token for gaining access to the `Kubernetes Dashboard`.

## #3.0.1 - Scalability - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-3-0-1-scalability-33edd89c3919)

No additional instructions

## #4 - All About Ingress - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-4-all-about-ingress-be59d651f11d)

No additional instructions
## #4.0.1 - Limits, Taints, and Affinities - [Link](https://medium.com/@weiyuan-liu/figuring-it-out-kubernetes-eks-aws-4-0-1-limits-taints-and-affinities-8f0d954bba79)

No additional instructions
