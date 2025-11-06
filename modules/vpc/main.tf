data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_dns_hostnames   = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-cluster" = "shared"
    "kubernetes.io/role/elb" = "1"
    "karpenter.sh/discovery" = "${var.project_name}-cluster"
  }
}

# VPC Endpoint for S3 (not managed by the VPC module)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  # Using the private route tables created by the VPC module
  route_table_ids = module.vpc.private_route_table_ids
  
  tags = {
    Name = "${var.project_name}-s3-endpoint-${var.environment}"
  }
}
