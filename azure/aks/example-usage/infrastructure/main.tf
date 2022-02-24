terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.91.0, < 3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ckeditor-cs"
    container_name       = "tfstate"
    key                  = "ckeditor-cs/infrastructure.terraform.tfstate"
    storage_account_name = "ckeditorcs"
  }
}

provider "azurerm" {
  features {}
}

module "infrastructure" {
  source = "../../infrastructure"

  resource_group_name     = "ckeditor-cs-infrastructure"
  resource_group_location = "germanywestcentral"

  ssh_public_key = var.ssh_public_key_path
}
