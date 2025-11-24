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

# -----------------------------------------------------------------
# 1. משיכת הסוד המאוחד מ-AWS Secrets Manager ופענוח ה-JSON
# -----------------------------------------------------------------

# משיכת ה-Secret ID לפי השם (app_secret_name)
data "aws_secretsmanager_secret" "app_secrets" {
  name = var.app_secret_name
}

# משיכת גרסת הסוד הנוכחית (ה-JSON string)
data "aws_secretsmanager_secret_version" "app_secrets_version" {
  secret_id = data.aws_secretsmanager_secret.app_secrets.id
}

# פענוח ה-JSON string לאובייקט (מפה) ב-Terraform
locals {
  # שימוש בפונקציה jsondecode כדי להמיר את המחרוזת לאובייקט
  app_secrets_map = jsondecode(data.aws_secretsmanager_secret_version.app_secrets_version.secret_string)
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

  db_name     = var.db_name
  db_username = var.db_username
  # הקטע הקריטי: שולפים את הסיסמה DB_PASSWORD מתוך האובייקט המפוענח
  db_password       = local.app_secrets_map["DB_PASSWORD"]
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