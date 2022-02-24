resource "azurerm_redis_cache" "redis" {
  name                          = local.name
  location                      = azurerm_resource_group.resource_group.location
  resource_group_name           = azurerm_resource_group.resource_group.name
  capacity                      = var.redis_cache_capacity
  family                        = var.redis_cache_family
  sku_name                      = var.redis_cache_sku_name
  enable_non_ssl_port           = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  redis_version                 = 6

  redis_configuration {
  }
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "${local.name}.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = local.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.virtual_network.id
  resource_group_name   = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_endpoint" "redis" {
  name                = "${local.name}-redis"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  subnet_id           = azurerm_subnet.redis.id

  private_dns_zone_group {
    name                 = "${local.name}-redis"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }

  private_service_connection {
    name                           = "${local.name}-redis"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_redis_cache.redis.id
    subresource_names              = ["redisCache"]
  }
}

resource "azurerm_private_dns_a_record" "redis" {
  name                = "@"
  zone_name           = azurerm_private_dns_zone.redis.name
  resource_group_name = azurerm_resource_group.resource_group.name
  ttl                 = 300
  records             = azurerm_private_endpoint.redis.custom_dns_configs[0].ip_addresses
}
