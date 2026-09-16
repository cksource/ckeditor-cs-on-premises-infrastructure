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

module "cs-with-ai-on-premises" {
  source = "./cs-with-ai-on-premises"

  aws_region = data.aws_region.current.region

  cs_license_key                     = var.cs_license_key
  ai_license_key                     = var.ai_license_key
  cs_docker_token                    = var.cs_docker_token
  ai_docker_token                    = var.ai_docker_token
  environments_management_secret_key = var.environments_management_secret_key
  providers_config                   = var.providers_config
  models_config                      = var.models_config

  cs_app = {
    version = var.cs_image_version
  }

  ai_app = {
    version = var.ai_image_version
  }
}
