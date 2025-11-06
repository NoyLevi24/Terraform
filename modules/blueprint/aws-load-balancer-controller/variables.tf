variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "irsa_role_arn" {
  description = "ARN of the IAM role for service account"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the cluster is deployed"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster is deployed"
  type        = string
}

variable "eks_dependency" {
  description = "Dependency on the EKS cluster"
  type        = any
  default     = null
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
}
