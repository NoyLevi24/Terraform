# Create VPC and networking
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = var.vpc_cidr
  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
}

# Create S3 Bucket
module "s3" {
  source = "./modules/s3"

  project_name      = var.project_name
  environment       = var.environment
  bucket_name       = "files"
  vpc_id            = module.vpc.vpc_id
  enable_versioning = var.enable_versioning

  depends_on = [module.vpc]
}

# Create RDS Database
module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = [var.vpc_cidr]
  private_subnet_ids = module.vpc.private_subnet_ids

  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class

  depends_on = [module.vpc]
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  # VPC and Networking
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # S3 Bucket
  s3_bucket_name = "${var.project_name}-${var.environment}-files"

  # Node Group Configuration
  instance_types = ["t3a.medium"]
  desired_size   = 2
  min_size       = 1
  max_size       = 3

  depends_on = [
    module.vpc,
    module.s3,
    module.rds
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }
}

# Security Group Rule to allow traffic from EKS nodes to RDS
resource "aws_security_group_rule" "rds_ingress_eks_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.rds_security_group_id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow PostgreSQL access from EKS nodes"
  
  # Ensure this is created after both RDS and EKS are created
  depends_on = [
    module.rds,
    module.eks
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}

# Create IAM Role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.47.1"

  role_name = "${var.project_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project_name
  }
}

# AWS Load Balancer Controller Module
module "aws_load_balancer_controller" {
  source = "./modules/blueprint/aws-load-balancer-controller"

  cluster_name      = module.eks.cluster_name
  irsa_role_arn     = module.aws_load_balancer_controller_irsa.iam_role_arn
  aws_region        = var.aws_region
  vpc_id            = module.vpc.vpc_id
  eks_dependency    = module.eks
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

/*
# Karpenter Module - Version 21.8.0
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.8.0"

  cluster_name = module.eks.cluster_name

  create_node_iam_role = false
  node_iam_role_arn    = module.eks.node_role_arn

  create_access_entry = false

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project_name
  }

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller
  ]
}

# Module 2: Karpenter Configuration 
module "karpenter_config" {
  source = "./modules/blueprint/karpenter"

  cluster_name         = module.eks.cluster_name
  node_iam_role_name   = module.eks.node_role_arn
  environment          = var.environment
  karpenter_dependency = module.karpenter

  depends_on = [module.karpenter]
}
*/
# ArgoCD Module
module "argocd" {
  source     = "./modules/blueprint/argocd"
  depends_on = [module.eks]
}

# Kube Prometheus Stack Module
module "kube_prometheus_stack" {
  source = "./modules/blueprint/kube-prometheus-stack"
  depends_on = [
    module.eks,
    module.argocd
  ]
}

