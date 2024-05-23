output "app_url" {
  value = "http://${aws_alb.main.dns_name}"
}
