# CKEditor AI Service On-Premises AWS Terraform module

Use this Terraform module to provision infrastructure hosted in AWS for
CKEditor AI Service On-Premises. A single module will create all the resources
needed to run the On-Premises application using ECS Fargate.

This module deploys the AI service in its **standalone** variant — with its own
database, Redis and management panel. If you already run Collaboration Server
On-Premises 5.0.0 or newer (see [`aws/ecs`](/aws/ecs)) and want both services to
share a single data layer, point the AI service at the same database and Redis
the Collaboration Server uses instead of creating new ones. See
[Integration with Collaboration Server On-Premises](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#integration-with-collaboration-server-on-premises).

**Note:** This module is made for Terraform. If you haven't worked with it
before, we highly recommend getting familiar with it first:
https://www.terraform.io/intro

## List of created resources

- Network resources: VPC, subnets, route tables, internet and NAT gateways.
- Load balancer and ECS cluster with an ECS task running the CKEditor AI Service
  On-Premises application.
- Redis and MySQL databases in private subnets.
- S3 bucket for the AI service file storage.

Note: This module will create only an HTTP listener for the load balancer. You
need to adjust the script to use your custom domain and HTTPS listeners.

## Usage
Ensure you have terraform in version `1.11.0` or higher and your AWS
credentials are configured properly.

1. Clone the repository
```
git clone git@github.com:cksource/ckeditor-cs-on-premises-infrastructure.git
```

2. Initialize terraform
```
cd aws/ecs-ai-service
terraform init
```

3. Create a `terraform.tfvars` file in the `aws/ecs-ai-service` folder with the
   following variables:
```
image_version = ""
license_key = ""
docker_token = ""
environments_management_secret_key = ""
providers_config = ""
```

Note:
- The `image_version` property should be set to the version of the CKEditor AI Service On-Premises image that you want to run. By default, the module uses the CKEditor AI Service On-Premises image with the "latest" tag. If you are using this module for a production environment, it's strongly recommended to change the container image tag to a numeric representation of the version you want to use. Refer to https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/changelog.html for the list of currently available versions.
- The `license_key` property can be found in [CKEditor Customer Portal](https://portal.ckeditor.com/) in your CKEditor AI Server subscription page.
- The `docker_token` property can be found in the CKEditor Customer Portal in your CKEditor AI Server subscription page in the *Download tokens* section. If you do not see any tokens, you can create them with the *Create token* button.
- The `environments_management_secret_key` property is your password, which is used to access the CKEditor AI Service On-Premises [management panel](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#step-4-create-an-environment-and-access-key).
- The `providers_config` property is a stringified JSON object with the LLM providers the service should use. At least one provider is required — the service will not start without it. It is named `providers_config` rather than `providers` because `providers` is a reserved argument of Terraform's `module` block; it is passed to the container as the `PROVIDERS` environment variable. Refer to https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html#llm-providers for the full list of options. For example:
```
providers_config = "{\"openai\":{\"type\":\"openai\",\"apiKeys\":[\"your-api-key\"]}}"
```
- The optional `models_config` property is a stringified JSON array overriding the list of available models. Leave it out to use the default model list of every configured provider. See https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html#custom-models.

4. You can change the AWS region in which the resources will be created in `aws/ecs-ai-service/main.tf`. Refer to the `aws/ecs-ai-service/ai-service-on-premises/variables.tf` file to see which properties of the application can be optionally configured in the module.

5. Create all required resources:
```
terraform apply
```

Note: It may take several minutes, wait until the command finishes.

The application URL will be printed as terraform output after all resources are
created. Open it to reach the management panel, sign in with your
`environments_management_secret_key` and create an environment and an access
key — you need both for your token endpoint.

## LLM provider credentials

`providers_config` is stored whole in Secrets Manager, API keys included, and
injected as the `PROVIDERS` environment variable. It is not split into
"keys in Secrets Manager, the rest in plain config", because neither side
supports it: the service reads `providers` as a single opaque JSON value (its
config keys are flat and resolved as `process.env[KEY]`, so there is no
per-provider variable to point a secret at), and an ECS `secrets` entry can
only populate an entire environment variable, never part of one. Passing the
blob as plain `environment` would leave the keys in the task definition, where
anyone with `ecs:DescribeTaskDefinition` can read them.

If you would rather not hold a provider API key at all, Amazon Bedrock can be
used without one: declare the provider with no `apiKeys` and the service falls
back to the ambient AWS credential chain, which on Fargate is the ECS task
role. The task role this module creates only grants access to the S3 bucket,
so you have to extend it yourself — add `bedrock:InvokeModel` and
`bedrock:InvokeModelWithResponseStream` for the models you intend to use to
`data.aws_iam_policy_document.task_role` in
`ai-service-on-premises/service.tf`. Bedrock also requires that model access
be enabled in the AWS account and region you deploy to.

## Number of instances

The module runs 2 application instances by default to keep the cost of the
example lower. The
[documentation recommends at least 3](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/requirements.html)
for high availability. Set `app.instances` in `main.tf` to change it.

## Database user

**Not appropriate for production credential management** — the application
must connect to MySQL as a dedicated, non-root user rather than the RDS
master user, and this module creates that user for you automatically via
an ECS init-sidecar, for two concrete reasons this isn't production-grade:
- It runs once **per task replica**, on every deployment (with
  `app.instances = 2`, that's two independent, concurrent executions
  every time you deploy).
- The RDS master (root) password is readable by the ECS task's
  execution role for this to work, even though it's only ever
  used by the short-lived bootstrap container, not the long-running
  application container.

A typical production setup instead attaches to an already-provisioned,
externally-managed MySQL user on an existing cluster, with your own
tooling (Vault, IAM auth, CI/CD) handling user creation and your own
network path into the database.

The same sidecar also sets the database character set to `utf8mb4` and its
collation to `utf8mb4_bin`, which is what the
[Deployment guide](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#mysql)
asks for; RDS creates the database itself with the server defaults.
