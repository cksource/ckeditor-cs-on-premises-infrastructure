terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3" // Change this if you want to create resources in a different AWS region
}

data "aws_region" "current" {}

module "ai-service-on-premises" {
  source = "./ai-service-on-premises"

  aws_region = data.aws_region.current.region

  license_key                        = var.license_key
  docker_token                       = var.docker_token
  environments_management_secret_key = var.environments_management_secret_key
  providers_config                   = var.providers_config
  models_config                      = var.models_config

  app = {
    version = var.image_version
  }
}
