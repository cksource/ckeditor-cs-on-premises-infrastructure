terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.91.0, < 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "random_string" "name_postfix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name = "${var.name_prefix}${random_string.name_postfix.result}"
}
