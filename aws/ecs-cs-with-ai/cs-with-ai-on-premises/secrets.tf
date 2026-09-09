# The two applications are licensed separately, so each one gets its own
# license key and its own registry credentials.
resource "aws_secretsmanager_secret" "cs_license_key" {
  name        = "cs-with-ai-on-premises-cs-license-key"
  description = "The license_key can be found in CKEditor Customer Portal in your CKEditor Collaboration Server On-Premises subscription page"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "cs_license_key" {
  secret_id     = aws_secretsmanager_secret.cs_license_key.id
  secret_string = var.cs_license_key
}

resource "aws_secretsmanager_secret" "ai_license_key" {
  name        = "cs-with-ai-on-premises-ai-license-key"
  description = "The license_key can be found in CKEditor Customer Portal in your CKEditor AI Server subscription page"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ai_license_key" {
  secret_id     = aws_secretsmanager_secret.ai_license_key.id
  secret_string = var.ai_license_key
}

resource "aws_secretsmanager_secret" "cs_docker_token" {
  name        = "cs-with-ai-on-premises-cs-docker-token"
  description = "The docker_token can be found in CKEditor Customer Portal in your CKEditor Collaboration Server On-Premises subscription page in the Download token section"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "cs_docker_token" {
  secret_id = aws_secretsmanager_secret.cs_docker_token.id
  secret_string = jsonencode({
    username = "cs",
    password = var.cs_docker_token
  })
}

resource "aws_secretsmanager_secret" "ai_docker_token" {
  name        = "cs-with-ai-on-premises-ai-docker-token"
  description = "The docker_token can be found in CKEditor Customer Portal in your CKEditor AI Server subscription page in the Download tokens section"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "ai_docker_token" {
  secret_id = aws_secretsmanager_secret.ai_docker_token.id
  secret_string = jsonencode({
    username = "ai-service",
    password = var.ai_docker_token
  })
}

# Shared: once both services run on one data layer the AI Service's own panel is
# disabled and everything is managed from the Collaboration Server panel, so
# both containers get the same value.
resource "aws_secretsmanager_secret" "environments_management_secret_key" {
  name        = "cs-with-ai-on-premises-environments-management-secret-key"
  description = "This is the password, that will be used to access the management panel that configures both services"

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
# a secret into part of one.
resource "aws_secretsmanager_secret" "providers_config" {
  name        = "cs-with-ai-on-premises-providers"
  description = "Stringified JSON with the LLM providers configuration, including their API keys"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "providers_config" {
  secret_id     = aws_secretsmanager_secret.providers_config.id
  secret_string = var.providers_config
}

# Shared: both services connect to the shared database as the same application
# user, so there is one password.
module "app_db_password" {
  source = "./modules/managed-password-secret"

  name        = "cs-with-ai-on-premises-app-db-password"
  description = "Password for the application's MySQL user, created by the db-bootstrap init container"
}
