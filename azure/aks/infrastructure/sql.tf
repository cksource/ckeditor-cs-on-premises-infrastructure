resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

resource "azurerm_private_dns_zone" "mysql" {
  name                = "mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = local.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.virtual_network.id
  resource_group_name   = azurerm_resource_group.resource_group.name
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = local.name
  resource_group_name    = azurerm_resource_group.resource_group.name
  location               = azurerm_resource_group.resource_group.location
  administrator_login    = var.mysql_user
  administrator_password = var.mysql_password != "" ? var.mysql_password : random_password.mysql_password.result
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.mysql.id
  sku_name               = var.mysql_flexible_server_sku_name
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id

  storage {
    auto_grow_enabled = true
    size_gb           = 20
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]
}

resource "azurerm_mysql_flexible_server_configuration" "max_allowed_packet" {
  name                = "max_allowed_packet"
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  value               = "209715200"
}

resource "azurerm_mysql_flexible_database" "mysql" {
  name                = "cksource"
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
