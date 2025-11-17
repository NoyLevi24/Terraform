# EKS Outputs
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "The security group ID of the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "The security group ID of the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

# ESO Outputs
output "eso_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = module.eso.eso_role_arn
}

output "eso_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  value       = module.eso.eso_namespace
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = module.eso.aws_account_id
}

# Helpful Commands
output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "argocd_url" {
  description = "Command to get ArgoCD URL"
  value       = "kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "grafana_url" {
  description = "Command to get Grafana URL"
  value       = "kubectl get svc -n monitoring prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}

output "argocd_initial_password" {
  description = "Command to get ArgoCD initial password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  sensitive   = true
}

output "eso_serviceaccount_annotation" {
  description = "Annotation to use in ServiceAccount for ESO"
  value       = "eks.amazonaws.com/role-arn: ${module.eso.eso_role_arn}"
}