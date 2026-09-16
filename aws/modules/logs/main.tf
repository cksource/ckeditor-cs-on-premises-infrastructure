terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = var.name
  retention_in_days = var.retention_in_days
}

data "aws_iam_policy_document" "logs" {
  statement {
    sid    = "UploadLogs"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
    ]
    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
  }
}

resource "aws_iam_role_policy" "logs" {
  name = "logs"
  role = var.task_execution_role_id

  policy = data.aws_iam_policy_document.logs.json
}
