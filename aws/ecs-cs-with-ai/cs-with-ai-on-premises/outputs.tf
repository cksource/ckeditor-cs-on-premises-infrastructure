output "cs_url" {
  value = "http://${aws_alb.main.dns_name}"
}

output "ai_service_url" {
  value = "http://${aws_alb.main.dns_name}:${local.ai_listener_port}"
}
