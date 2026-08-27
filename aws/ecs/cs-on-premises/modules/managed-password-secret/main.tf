terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

ephemeral "random_password" "generated" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id                = aws_secretsmanager_secret.this.id
  secret_string_wo         = ephemeral.random_password.generated.result
  secret_string_wo_version = 1
}
