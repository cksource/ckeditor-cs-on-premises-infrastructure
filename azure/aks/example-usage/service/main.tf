terraform {
  backend "azurerm" {
    resource_group_name  = "cksource-cs"
    container_name       = "tfstate"
    key                  = "cksource-cs/service.terraform.tfstate"
    storage_account_name = "cksource-cs"
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_group_name = "cksource-cs"
  storage_account_key = "cksource-cs"
}

data "terraform_remote_state" "infrastructure" {
  backend = "azurerm"

  config = {
    resource_group_name  = local.resource_group_name
    container_name       = "tfstate"
    key                  = "cksource-cs/infrastructure.terraform.tfstate"
    storage_account_name = local.storage_account_name
  }
}

module "service" {
  source = "../../service"

  docker_token                       = var.docker_token
  license_key                        = var.license_key
  environments_management_secret_key = var.environments_management_secret_key

  kube_config = data.terraform_remote_state.infrastructure.outputs.kube_config

  mysql_host     = data.terraform_remote_state.infrastructure.outputs.mysql_host
  mysql_user     = data.terraform_remote_state.infrastructure.outputs.mysql_user
  mysql_password = data.terraform_remote_state.infrastructure.outputs.mysql_password
  mysql_database = data.terraform_remote_state.infrastructure.outputs.mysql_database

  redis_host     = data.terraform_remote_state.infrastructure.outputs.redis_host
  redis_password = data.terraform_remote_state.infrastructure.outputs.redis_password

  storage_container    = data.terraform_remote_state.infrastructure.outputs.storage_container
  storage_account_key  = data.terraform_remote_state.infrastructure.outputs.storage_account_key
  storage_account_name = data.terraform_remote_state.infrastructure.outputs.storage_account_name
}
