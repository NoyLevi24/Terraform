output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "rds_username" {
  description = "The master username for the RDS instance"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "rds_database_name" {
  description = "The name of the database"
  value       = module.db.db_instance_name
}

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = module.db.db_instance_identifier
}

output "rds_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  value       = module.rds_security_group.security_group_id
}

output "rds_port" {
  description = "The port on which the DB accepts connections"
  value       = module.db.db_instance_port
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db.db_instance_status
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db.db_instance_availability_zone
}
