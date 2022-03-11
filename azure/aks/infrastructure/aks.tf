resource "azurerm_log_analytics_workspace" "ckeditor_cs" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = local.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "ckeditor_cs" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.ckeditor_cs.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  workspace_resource_id = azurerm_log_analytics_workspace.ckeditor_cs.id
  workspace_name        = azurerm_log_analytics_workspace.ckeditor_cs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = local.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = local.name

  private_cluster_enabled       = false
  public_network_access_enabled = true

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  default_node_pool {
    name                = "agentpool"
    vm_size             = var.node_pool_vm_size
    vnet_subnet_id      = azurerm_subnet.kubernetes.id
    enable_auto_scaling = true
    min_count           = var.aks_node_pool_min_count
    max_count           = var.aks_node_pool_max_count
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    ingress_application_gateway {
      enabled   = true
      subnet_id = azurerm_subnet.ingress.id
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.ckeditor_cs.id
    }
  }

  network_profile {
    load_balancer_sku  = "Standard"
    network_plugin     = "azure"
    docker_bridge_cidr = "171.17.0.1/16"
    dns_service_ip     = "10.0.20.10"
    service_cidr       = "10.0.20.0/22"
    network_policy     = "azure"
  }
}
