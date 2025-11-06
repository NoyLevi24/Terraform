# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

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

# S3 Outputs
output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

# EKS Outputs
output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

# Helpful Commands (simplified format)
output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "helm_install_command" {
  description = "Command to install the application with Helm"
  value       = "helm upgrade --install journai ./helm-chart --namespace journai --create-namespace -f values.yaml -f values-secrets.yaml"
}

# Summary of important values for values-secrets.yaml
output "values_for_helm" {
  description = "Values needed for values-secrets.yaml"
  sensitive   = true
  value = {
    rds_endpoint = module.rds.rds_endpoint
    s3_bucket    = module.s3.bucket_name
    eks_cluster  = module.eks.cluster_name
    aws_region   = var.aws_region
    db_name      = var.db_name
    db_username  = var.db_username
  }
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = "Run: kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "Run: kubectl get svc -n monitoring prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_initial_password" {
  description = "Command to get ArgoCD initial password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}
