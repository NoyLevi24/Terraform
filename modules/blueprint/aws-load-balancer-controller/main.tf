# Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"
  
  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.irsa_role_arn
  }

  # VPC ID is required for the controller
  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  # AWS region
  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [var.eks_dependency]
}

output "alb_controller_status" {
  description = "AWS Load Balancer Controller installation status"
  value       = "Installed via Terraform"
}
