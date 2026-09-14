# Both task definitions share these two roles. Their permissions are identical -
# read the same secrets, write to the same log group, use the same bucket - so
# splitting them per service would only duplicate the policies.
resource "aws_iam_role" "task_execution_role" {
  name = "cs-with-ai-on-premises-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    sid     = "AllowAccessToCsWithAiOnPremisesSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.cs_license_key.arn,
      aws_secretsmanager_secret.ai_license_key.arn,
      aws_secretsmanager_secret.cs_docker_token.arn,
      aws_secretsmanager_secret.ai_docker_token.arn,
      aws_secretsmanager_secret.environments_management_secret_key.arn,
      aws_secretsmanager_secret.providers_config.arn,
      module.app_db_password.secret_arn,
      aws_rds_cluster.cluster.master_user_secret[0].secret_arn,
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_role" {
  name = "cs-with-ai-on-premises-secrets"
  role = aws_iam_role.task_execution_role.id

  policy = data.aws_iam_policy_document.task_execution_role.json
}

resource "aws_iam_role" "task_role" {
  name = "cs-with-ai-on-premises-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "task_role" {
  statement {
    sid     = "AllowAccessToS3Bucket"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.storage.arn,
      "${aws_s3_bucket.storage.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task_role" {
  name = "cs-with-ai-on-premises-s3-access"
  role = aws_iam_role.task_role.id

  policy = data.aws_iam_policy_document.task_role.json
}
