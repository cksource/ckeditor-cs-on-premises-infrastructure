resource "aws_secretsmanager_secret" "license_key" {
  name        = "cs-on-premises-license-key"
  description = "The license_key can be found in CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "license_key" {
  secret_id     = aws_secretsmanager_secret.license_key.id
  secret_string = var.license_key
}

resource "aws_secretsmanager_secret" "docker_token" {
  name        = "cs-on-premises-docker-token"
  description = "The docker_token can be found in CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page in the Download token section. If you do not see any tokens, you can create them with the `Create new token` button."

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "docker_token" {
  secret_id = aws_secretsmanager_secret.docker_token.id
  secret_string = jsonencode({
    username = "cs",
    password = var.docker_token
  })
}

resource "aws_secretsmanager_secret" "environments_management_secret_key" {
  name        = "cs-on-premises-environments-management-secret-key"
  description = "This is the password, that will be used to access the Collaboration Server On-Premises management panel"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "environments_management_secret_key" {
  secret_id     = aws_secretsmanager_secret.environments_management_secret_key.id
  secret_string = var.environments_management_secret_key
}

resource "random_string" "database_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "database_password" {
  name        = "cs-on-premises-database-password"
  description = "The license_key can be found in CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = random_string.database_password.result
}
