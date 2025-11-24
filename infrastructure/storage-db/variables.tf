variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "journai"
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "journaidb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

# Secrets Manager (מחליף את db_password)
variable "app_secret_name" {
  description = "The name of the AWS Secrets Manager entry containing structured application secrets (JSON)."
  type        = string
  default     = "journai/app-secrets"
}


# S3 Configuration
variable "s3_bucket_name" {
  description = "Name for the S3 bucket"
  type        = string
  default     = "journai-dev-files"
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}