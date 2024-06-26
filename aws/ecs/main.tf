terraform {
  required_version = ">= 1.7.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.47"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.1"
    }
  }
}

provider "aws" {
  region = "eu-west-3" // Change this if you want to create resources in a different AWS region
}

data "aws_region" "current" {}

module "cs-on-premises" {
  source = "./cs-on-premises"

  aws_region = data.aws_region.current.name

  license_key                        = var.license_key
  docker_token                       = var.docker_token
  environments_management_secret_key = var.environments_management_secret_key

  app = {
    version = var.image_version
  }
}
