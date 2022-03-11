resource "azurerm_virtual_network" "virtual_network" {
  name                = local.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "kubernetes" {
  name                 = "${local.name}-kubernetes"
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "mysql" {
  name                 = "${local.name}-mysql"
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = ["10.0.4.0/22"]

  delegation {
    name = "flexibleServers"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "storage" {
  name                 = "${local.name}-storage"
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = ["10.0.8.0/22"]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "redis" {
  name                 = "${local.name}-redis"
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = ["10.0.12.0/22"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "ingress" {
  name                 = "${local.name}-ingress"
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  resource_group_name  = azurerm_resource_group.resource_group.name
  address_prefixes     = ["10.0.16.0/22"]
}
