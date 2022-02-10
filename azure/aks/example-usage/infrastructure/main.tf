terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.91.0, < 3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "cksource-cs"
    container_name       = "tfstate"
    key                  = "cksource-cs/infrastructure.terraform.tfstate"
    storage_account_name = "cksource-cs"
  }
}

locals {
  region              = "germanywestcentral"
  resource_group_name = "cksource-cs-infrastructure"
}

provider "azurerm" {
  features {}
}

module "infrastructure" {
  source = "../../infrastructure"

  resource_group_name     = local.resource_group_name
  resource_group_location = local.region
}
