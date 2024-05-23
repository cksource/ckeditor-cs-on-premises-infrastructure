resource "aws_cloudwatch_log_group" "log_group" {
  name              = "cs-on-premises-logs"
  retention_in_days = 30
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
  role = aws_iam_role.task_execution_role.id

  policy = data.aws_iam_policy_document.logs.json
}
