terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    # Required by EKS module
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.5.7"

  backend "remote" {
    organization = "JournAI"
    workspaces {
      name = "dev-eks"
    }
  }
}

# AWS Provider for EKS resources
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Terraform   = "true"
    }
  }
}

# Kubernetes provider for EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

# Helm provider for managing Kubernetes packages
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
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

# Get RDS and S3 information from storage-db state
data "terraform_remote_state" "storage_db" {
  backend = "remote"

  config = {
    organization = "JournAI"
    workspaces = {
      name = "dev-storage-db"
    }
  }
}

# EKS Cluster Module
module "eks" {
  source = "/home/noylevi/Bootcamp-Project/terraform/modules/eks"

  project_name = var.project_name
  environment  = var.environment

  # VPC and Networking
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  # S3 Bucket
  s3_bucket_name = data.terraform_remote_state.storage_db.outputs.s3_bucket_name

  # Node Group Configuration
  instance_types = var.node_instance_types
  desired_size   = var.node_desired_capacity
  min_size       = var.node_min_capacity
  max_size       = var.node_max_capacity

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
  security_group_id        = data.terraform_remote_state.storage_db.outputs.rds_security_group_id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow PostgreSQL access from EKS nodes"

  # Ensure this is created after both RDS and EKS are created
  depends_on = [
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
    Project     = var.project_name
    Terraform   = "true"
  }
}

# AWS Load Balancer Controller Module
module "aws_load_balancer_controller" {
  source = "/home/noylevi/Bootcamp-Project/terraform/modules/blueprint/aws-load-balancer-controller"

  cluster_name      = module.eks.cluster_name
  irsa_role_arn     = module.aws_load_balancer_controller_irsa.iam_role_arn
  aws_region        = var.aws_region
  vpc_id            = data.terraform_remote_state.networking.outputs.vpc_id
  eks_dependency    = module.eks
  oidc_provider_arn = module.eks.oidc_provider_arn

  depends_on = [module.eks]
}

# ArgoCD Module
module "argocd" {
  source     = "/home/noylevi/Bootcamp-Project/terraform/modules/blueprint/argocd"
  depends_on = [module.eks]
}

# Kube Prometheus Stack Module
module "kube_prometheus_stack" {
  source = "/home/noylevi/Bootcamp-Project/terraform/modules/blueprint/kube-prometheus-stack"
  depends_on = [
    module.eks,
    module.argocd
  ]
}