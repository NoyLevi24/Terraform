# RDS Outputs
output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.rds_endpoint
}

output "rds_username" {
  description = "The master username for the RDS instance"
  value       = module.rds.rds_username
  sensitive   = true
}

output "rds_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = module.rds.rds_security_group_id
}

# S3 Outputs
output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

# Values for Helm
output "values_for_helm" {
  description = "Values needed for values-secrets.yaml"
  sensitive   = true
  value = {
    rds_endpoint = module.rds.rds_endpoint
    s3_bucket    = module.s3.bucket_name
    db_name      = var.db_name
    db_username  = var.db_username
  }
}
