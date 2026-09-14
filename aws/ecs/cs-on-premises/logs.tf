module "logs" {
  source = "../../modules/logs"

  name                   = "cs-on-premises-logs"
  task_execution_role_id = aws_iam_role.task_execution_role.id
}
