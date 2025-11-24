module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.8.0"
  
  # Cluster configuration
  name               = "${var.project_name}-cluster"
  kubernetes_version = var.cluster_version
  endpoint_public_access                   = true
  endpoint_private_access                  = true
  enable_cluster_creator_admin_permissions = true
  
  # Network configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids
  
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    "journai-eks-nodes" = {
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      instance_types = var.instance_types
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type = var.environment == "prod" ? "ON_DEMAND" : "SPOT"
      
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
  
  # Cluster add-ons
  addons = {
    coredns = {
      addon_version     = "v1.12.1-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {
      addon_version     = "v1.33.3-eksbuild.4"
      resolve_conflicts = "OVERWRITE"
    }
    # VPC CNI removed - will be installed manually
    aws-ebs-csi-driver = {
      addon_version            = "v1.52.1-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }
  
  # Security group configuration
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.project_name
  }
}

# Create IAM role for EBS CSI Driver
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.47.1"
  
  role_name = "${var.project_name}-ebs-csi-${var.environment}"
  
  attach_ebs_csi_policy = true
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
  
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create IAM role for VPC CNI
module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.47.1"
  
  role_name = "${var.project_name}-vpc-cni-${var.environment}"
  
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
  
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}