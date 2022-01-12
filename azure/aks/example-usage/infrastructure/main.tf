terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.91.0, < 3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "cksource"
    container_name       = "tfstate"
    key                  = "cksource-cs/infrastructure.terraform.tfstate"
    storage_account_name = "cksource"
  }
}

provider "azurerm" {
  features {}
}

module "infrastructure" {
  source = "../../infrastructure"

  resource_group_name     = "cksource-cs"
  resource_group_location = "germanywestcentral"
}
