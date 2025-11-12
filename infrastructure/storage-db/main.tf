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
      name = "dev-storage-db"
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

# Get VPC and subnets from networking state
data "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = "JournAI"
    workspaces = {
      name = "dev-networking"
    }
  }
}

# Create RDS Database
module "rds" {
  source = "/home/noylevi/Bootcamp-Project/terraform/modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  vpc_cidr           = [data.terraform_remote_state.networking.outputs.vpc_cidr]
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

}

# Create S3 Bucket
module "s3" {
  source = "/home/noylevi/Bootcamp-Project/terraform/modules/s3"

  project_name      = var.project_name
  environment       = var.environment
  bucket_name       = "files"
  vpc_id            = data.terraform_remote_state.networking.outputs.vpc_id
  enable_versioning = var.enable_versioning

  depends_on = [module.rds]
}
