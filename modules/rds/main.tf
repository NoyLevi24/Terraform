module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.13"  # Compatible with AWS Provider >= 6.0.0

  identifier = "${var.project_name}-db-${var.environment}"

  # Database settings
  engine               = "postgres"
  engine_version       = "16"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = var.db_instance_class

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database credentials
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network
  create_db_subnet_group = true
  subnet_ids            = var.private_subnet_ids
  vpc_security_group_ids = [module.rds_security_group.security_group_id]
  
  # Maintenance
  maintenance_window      = "Mon:04:00-Mon:05:00"
  backup_window          = "03:00-04:00"
  backup_retention_period = var.environment == "prod" ? 35 : 7
  
  # High availability
  multi_az = var.environment == "prod" ? true : false
  
  # Security
  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment == "prod" ? false : true
  manage_master_user_password = false
  
  # Monitoring
  monitoring_interval = 30
  monitoring_role_name = "${var.project_name}-rds-monitoring-role-${var.environment}"
  create_monitoring_role = true
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7
  
  # Parameters
  parameters = [
    {
      name  = "log_connections"
      value = "1"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "rds.force_ssl"
      value = "0"
    }
  ]

  # Tags
  tags = {
      Name        = "${var.project_name}-db"
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
  }
}

# Security Group for RDS
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = join(",", var.vpc_cidr)  # Convert list to comma-separated string
    }
  ]

  # Egress rules
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${var.project_name}-rds-sg-${var.environment}"
  }
}


