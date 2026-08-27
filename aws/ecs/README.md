# CKEditor Collaboration Server On-Premises AWS Terraform module

Use this Terraform module to provision infrastructure hosted in AWS for Collaboration Server On-Premises. A single module will create all the resources needed to run an On-Premises application using ECS Fargate.

**Note:** This module is made for Terraform. If you haven't worked with it before, we highly recommend getting familiar with it first: https://www.terraform.io/intro

## List of created resources

- Network resources: VPC, subnets, route tables, internet and NAT gateways.
- Load balancer and ECS cluster with ECS task running CKEditor Collaboration Server On-Premises application.
- Redis and MySQL databases in private subnets.
- S3 bucket for Easy Image and collaboration storage.

Note: This module will create only HTTP listener for the load balancer. You need to adjust the script to use your custom domain and HTTPS listeners.

## Usage
Ensure you have terraform in version `1.11.0` or higher and your AWS credentials are configured properly.

1. Clone the repository
```
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
```

2. Initialize terraform
```
cd aws/ecs
terraform init
```

3. Create a `terraform.tfvars` file in `aws/ecs` folder with the following variables:
```
image_version = ""
license_key = ""
docker_token = ""
environments_management_secret_key = ""
```

Note:
- The `image_version` property should be set to the version of CKEditor Collaboration Server On-Premises image that you want to run. By default, the module uses the CKEditor Collaboration Server On-Premises with the "latest" tag. If you are using this module for a production environment, it's strongly recommended to change the container image tag to a numeric representation of the version you want to use. Refer to https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/changelog.html for the list of currently available versions.
- The `license_key` property can be found in [CKEditor Customer Portal](https://portal.ckeditor.com/) in your CKEditor Collaboration Server On-Premises subscription page.
- The `docker_token` property can be found in the CKEditor Customer Portal in your CKEditor Collaboration Server On-Premises subscription page in the *Download token* section. If you do not see any tokens, you can create them with the *Create new token* button.
- The `environments_management_secret_key` property is your password, which is used to access the Collaboration Server On-Premises [management panel](https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/management.html)

1. You can change the AWS region in which the resources will be created in `aws/ecs/main.tf`. Refer to the `aws/ecs/cs-on-premises/variables.tf` file to see which properties of the application can be optionally configured in the module.

2. Create all required resources:
```
terraform apply
```

Note: It may take several minutes, wait until the command finishes.

Application URL will be printed as terraform output after all resources are created.

## Database user

**Not appropriate for production credential management** — the application
must connect to MySQL as a dedicated, non-root user rather than the RDS
master user, and this module creates that user for you automatically via
an ECS init-sidecar, for two concrete reasons this isn't production-grade:
- It runs once **per task replica**, on every deployment (with
  `desired_count = 2`, that's two independent, concurrent executions
  every time you deploy).
- The RDS master (root) password is readable by the ECS task's
  execution role for this to work, even though it's only ever
  used by the short-lived bootstrap container, not the long-running
  application container.

A typical production setup instead attaches to an already-provisioned,
externally-managed MySQL user on an existing cluster, with your own
tooling (Vault, IAM auth, CI/CD) handling user creation and your own
network path into the database.
