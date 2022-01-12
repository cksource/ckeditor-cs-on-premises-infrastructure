output "kube_config" {
  value     = module.infrastructure.kube_config
  sensitive = true
}

output "mysql_host" {
  value = module.infrastructure.mysql_host
}

output "mysql_user" {
  value     = module.infrastructure.mysql_user
  sensitive = true
}

output "mysql_password" {
  value     = module.infrastructure.mysql_password
  sensitive = true
}

output "mysql_database" {
  value = module.infrastructure.mysql_database
}

output "redis_host" {
  value = module.infrastructure.redis_host
}

output "redis_password" {
  value     = module.infrastructure.redis_password
  sensitive = true
}

output "storage_account_name" {
  value = module.infrastructure.storage_account_name
}

output "storage_account_key" {
  value     = module.infrastructure.storage_account_key
  sensitive = true
}

output "storage_container" {
  value = module.infrastructure.storage_container
}
