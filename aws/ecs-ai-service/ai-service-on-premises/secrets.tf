resource "aws_secretsmanager_secret" "license_key" {
  name        = "ai-service-on-premises-license-key"
  description = "The license_key can be found in CKEditor Customer Portal in your CKEditor AI Service On-Premises subscription page"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "license_key" {
  secret_id     = aws_secretsmanager_secret.license_key.id
  secret_string = var.license_key
}

resource "aws_secretsmanager_secret" "docker_token" {
  name        = "ai-service-on-premises-docker-token"
  description = "The docker_token can be found in CKEditor Customer Portal in your CKEditor AI Service On-Premises subscription page in the Download tokens section. If you do not see any tokens, you can create them with the `Create token` button."

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "docker_token" {
  secret_id = aws_secretsmanager_secret.docker_token.id
  secret_string = jsonencode({
    username = "ai-service",
    password = var.docker_token
  })
}

resource "aws_secretsmanager_secret" "environments_management_secret_key" {
  name        = "ai-service-on-premises-environments-management-secret-key"
  description = "This is the password, that will be used to access the CKEditor AI Service On-Premises management panel"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "environments_management_secret_key" {
  secret_id     = aws_secretsmanager_secret.environments_management_secret_key.id
  secret_string = var.environments_management_secret_key
}

# The whole `providers` value is kept here, API keys included, rather than only
# the keys themselves. The service reads `providers` as a single opaque JSON
# blob - config keys are flat and looked up as `process.env[KEY]`, so there is
# no per-provider variable such as `PROVIDERS_OPENAI_APIKEYS` to point at a
# secret, and ECS can only populate a whole environment variable, never splice
# a secret into part of one. Passing the blob as plain `environment` would put
# the keys in the task definition, readable by anyone with
# `ecs:DescribeTaskDefinition`, so the entire value becomes the secret.
#
# To avoid holding a provider API key at all, use the `bedrock` provider with
# no `apiKeys`: it then falls back to the ambient AWS credential chain, which
# on Fargate is this task's role. If you go that way, the role created in
# `service.tf` is not enough on its own - it only grants S3 access - so add
# `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` on the
# Bedrock models you use to `data.aws_iam_policy_document.task_role`. Other
# providers authenticate with their own API keys, so they need no IAM changes.
# See the README.
resource "aws_secretsmanager_secret" "providers_config" {
  name        = "ai-service-on-premises-providers"
  description = "Stringified JSON with the LLM providers configuration, including their API keys"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "providers_config" {
  secret_id     = aws_secretsmanager_secret.providers_config.id
  secret_string = var.providers_config
}

module "app_db_password" {
  source = "../../modules/managed-password-secret"

  name        = "ai-service-on-premises-app-db-password"
  description = "Password for the application's MySQL user, created by the db-bootstrap init container"
}
