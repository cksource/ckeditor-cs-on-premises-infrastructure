output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config
  sensitive = true
}

output "mysql_host" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_user" {
  value     = azurerm_mysql_flexible_server.mysql.administrator_login
  sensitive = true
}

output "mysql_password" {
  value     = azurerm_mysql_flexible_server.mysql.administrator_password
  sensitive = true
}

output "mysql_database" {
  value = azurerm_mysql_flexible_database.mysql.name
}

output "redis_host" {
  value = azurerm_redis_cache.redis.hostname
}

output "redis_password" {
  value     = azurerm_redis_cache.redis.primary_access_key
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}

output "storage_container" {
  value = azurerm_storage_container.storage.name
}
