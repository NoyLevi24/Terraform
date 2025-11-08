terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15"
    }
  }

  required_version = ">= 1.5.7"

  backend "remote" {
    organization = "JournAI"

    workspaces {
      name = "dev-networking"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = var.project_name
      Terraform   = "true"
    }
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  project_name           = var.project_name
  environment            = var.environment
  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnets
  private_subnet_cidrs  = var.private_subnets
}
