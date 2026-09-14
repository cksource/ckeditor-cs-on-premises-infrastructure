output "log_group_name" {
  value = aws_cloudwatch_log_group.log_group.name
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.log_group.arn
}
