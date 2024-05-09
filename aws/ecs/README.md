# CKEditor Collaboration Server On-Premises AWS Terraform module

Use this Terraform module to provision infrastructure hosted in AWS for Collaboration Server On-Premises. A single module will create all the resources needed to run On-Premises application using ECS Fargate.

**Note:** This module are made for Terraform. If you haven't worked with it before, we highly recommend getting familiar with it first: https://www.terraform.io/intro

## List of created resources

- network resources: VPC, subnets, route tables, internet and NAT gateways
- load balancer and ECS cluster with ECS task running CKEditor Collaboration Server On-Premises application
- redis and m=MySQL databases in private subnets
- s3 bucket for Easy Image and collaboration storage

## Usage
Make sure that you have terraform in version `1.7.4` or higher and your AWS credentials are configured properly.

1. Clone the repository
```
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
```

2. Initialize terraform
```
cd aws/ecs
terraform init
```

3. Change the version of the application in `aws/ecs/main.tf`. Refer to https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/changelog.html for the list of currently available versions. You can also change the AWS region in which the resources will be created.

4. (Optionally) Create a `terraform.tfvars` file in `aws/ecs` folder with the following variables:
```
license_key = ""
docker_token = ""
environments_management_secret_key = ""
```

Note:
- The `license_key` can be found in [CKEditor Ecosystem Dashboard](https://dashboard.ckeditor.com/) in your CKEditor Collaboration Server On-Premises subscription page.
- The `docker_token` can be found in the CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page in the *Download token* section. If you do not see any tokens, you can create them with the *Create new token* button.
- The `environments_management_secret_key` is your password, which be used to access the Collaboration Server On-Premises [management panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)

5. Create all required resources:
```
terraform apply
```

Note: It may take several minutes, wait until the command finishes.

Application URL will be printed as terraform output after all resources are created.
