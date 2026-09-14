# Collaboration Server with CKEditor AI Service On-Premises AWS Terraform module

Use this Terraform module to provision infrastructure hosted in AWS that runs
CKEditor Collaboration Server On-Premises and CKEditor AI Service On-Premises
on **one shared data layer** — the compatible mode. A single module
creates everything needed for both applications, running them as two ECS
Fargate services against the same database and the same Redis instance.

Running them this way means:

- **Shared environments** — every environment and access key created in the
  Collaboration Server management panel is available to the AI Service
  automatically.
- **A single management panel** — the AI Service's own panel is disabled, and
  both services are configured from the Collaboration Server panel.
- **A single token endpoint** — one JWT carries `auth.collaboration` for
  collaboration roles and `auth.ai.permissions` for AI access.

There is nothing to switch on: the AI Service detects the Collaboration Server
through the shared database by itself. What matters is that the database and
Redis settings are identical on both sides, so this module defines them once
(`local.shared_data_layer_environment` and `local.shared_data_layer_secrets`)
and splices them into both task definitions.

> :warning: Compatible mode requires Collaboration Server On-Premises **5.0.0
> or newer**. The two services are released together, and keeping them on the
> same version is strongly recommended — set `cs_image_version` and
> `ai_image_version` to the same release and upgrade them at the same time.

See
[Integration with Collaboration Server On-Premises](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#integration-with-collaboration-server-on-premises)
for the product-side description of this setup.

**Note:** This module is made for Terraform. If you haven't worked with it
before, we highly recommend getting familiar with it first:
https://www.terraform.io/intro

If you only need one of the two services, use [`aws/ecs`](/aws/ecs) for the
Collaboration Server on its own or
[`aws/ecs-ai-service`](/aws/ecs-ai-service) for the AI Service on its own.

## List of created resources

- Network resources: VPC, subnets, route tables, internet and NAT gateways.
- One load balancer and one ECS cluster running two ECS services: the
  Collaboration Server and the CKEditor AI Service.
- One Redis and one MySQL database in private subnets, shared by both services.
- S3 bucket for Easy Image and collaboration storage.
- A Cloud Map private DNS namespace so the Collaboration Server can reach the
  AI Service inside the VPC.

Note: This module will create only HTTP listeners for the load balancer. You
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
cd aws/ecs-cs-with-ai
terraform init
```

3. Create a `terraform.tfvars` file in the `aws/ecs-cs-with-ai` folder with the
   following variables:
```
cs_image_version = ""
ai_image_version = ""
cs_license_key = ""
ai_license_key = ""
cs_docker_token = ""
ai_docker_token = ""
environments_management_secret_key = ""
providers_config = ""
```

Note:
- The two applications are licensed separately, so **each one needs its own license key and its own registry download token**. Both are found in the [CKEditor Customer Portal](https://portal.ckeditor.com/): `cs_license_key` and `cs_docker_token` on your CKEditor Collaboration Server On-Premises subscription page, `ai_license_key` and `ai_docker_token` on your CKEditor AI Server subscription page. In each case the token is in the *Download token* section — if you do not see any tokens, you can create them there.
- The `cs_image_version` and `ai_image_version` properties should be set to the versions you want to run. Both default to the "latest" tag; for a production environment it's strongly recommended to pin them to the same numeric version. Refer to https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/changelog.html and https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/changelog.html for the lists of currently available versions.
- The `environments_management_secret_key` property is your password to the management panel. Unlike the license keys, this one is **shared** — it is the single panel that configures both services.
- The `providers_config` property is a stringified JSON object with the LLM providers the AI Service should use. At least one provider is required — the service will not start without it. It is named `providers_config` rather than `providers` because `providers` is a reserved argument of Terraform's `module` block; it is passed to the container as the `PROVIDERS` environment variable. Refer to https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html#llm-providers for the full list of options. For example:
```
providers_config = "{\"openai\":{\"type\":\"openai\",\"apiKeys\":[\"your-api-key\"]}}"
```
- The optional `models_config` property is a stringified JSON array overriding the list of available models. Leave it out to use the default model list of every configured provider. See https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/configuration.html#custom-models.

4. You can change the AWS region in which the resources will be created in `aws/ecs-cs-with-ai/main.tf`. Refer to the `aws/ecs-cs-with-ai/cs-with-ai-on-premises/variables.tf` file to see which properties of the two applications can be optionally configured — they are sized independently through the `cs_app` and `ai_app` objects.

5. Create all required resources:
```
terraform apply
```

Note: It may take several minutes, wait until the command finishes.

Two URLs are printed as terraform output. Open `cs_url` to reach the management
panel, sign in with your `environments_management_secret_key`, and create an
environment and an access key there — they apply to both services.

## Load balancer ports

Browsers need to reach both applications, so one load balancer carries them on
two ports rather than requiring two DNS names for host-based routing:

| Output | Address | Service |
| --- | --- | --- |
| `cs_url` | `http://<alb>` (port 80) | Collaboration Server, including the management panel |
| `ai_service_url` | `http://<alb>:8080` | CKEditor AI Service |

Path-based routing on a single port is deliberately avoided — the two services
do not have disjoint URL prefixes. Once you put your own domains and HTTPS
listeners in front of this, host-based routing is the better arrangement.

## AI_API_BASE_URL

The Collaboration Server management panel proxies AI API calls, and the address
it uses defaults to the Collaboration Server's own port. That default is correct
only when both services run inside a single process, which is not the case here
— they are two ECS services. This module therefore sets `AI_API_BASE_URL` on the
Collaboration Server to the AI Service's Cloud Map address
(`http://ai-service.cs-with-ai.internal:8000`), which keeps that traffic inside
the VPC instead of hairpinning through the public load balancer.

## Storage

The AI Service runs with `STORAGE_DRIVER=database`, so its files live in the SQL
database both services already share and compatible mode needs no extra storage
for it. The Collaboration Server keeps its own S3 bucket for Easy Image and
collaboration storage — sharing a data layer does not mean sharing a storage
driver. To put AI files in that same bucket instead, set the AI Service's
`STORAGE_DRIVER` to `s3` along with `STORAGE_BUCKET` and `STORAGE_REGION` in
`cs-with-ai-on-premises/service-ai.tf`; the shared task role already has access
to it.

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
`data.aws_iam_policy_document.task_role` in `cs-with-ai-on-premises/iam.tf`.
Bedrock also requires that model access be enabled in the AWS account and
region you deploy to.

## Number of instances

The module runs 2 instances of each service by default to keep the cost of the
example lower. The documentation recommends at least 3 for high availability.
Set `cs_app.instances` and `ai_app.instances` in `main.tf` to change them —
the two scale independently.

## Database user

**Not appropriate for production credential management** — the applications
must connect to MySQL as a dedicated, non-root user rather than the RDS
master user, and this module creates that user for you automatically via
an ECS init-sidecar, for two concrete reasons this isn't production-grade:
- It runs once **per task replica of both services**, on every deployment
  (with the defaults, that's four independent, concurrent executions every
  time you deploy). The sidecar is attached to both task definitions rather
  than only one because ECS cannot order one service's start-up against
  another's, so whichever task comes up first has to be able to bootstrap.
  The SQL is idempotent, so the repeats are harmless.
- The RDS master (root) password is readable by the ECS tasks'
  execution role for this to work, even though it's only ever
  used by the short-lived bootstrap container, not the long-running
  application containers.

A typical production setup instead attaches to an already-provisioned,
externally-managed MySQL user on an existing cluster, with your own
tooling (Vault, IAM auth, CI/CD) handling user creation and your own
network path into the database.

Both applications connect as that single user. In compatible mode they share
the schema, so one user holding the privileges both services need is enough.
The same sidecar also sets the database character set to `utf8mb4` and its
collation to `utf8mb4_bin`, which is what the
[Deployment guide](https://ckeditor.com/docs/cs/latest/onpremises/ckeditor-ai-onpremises/deployment.html#mysql)
asks for; RDS creates the database itself with the server defaults.
