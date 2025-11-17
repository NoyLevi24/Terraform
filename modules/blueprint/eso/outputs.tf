# modules/blueprint/eso/outputs.tf

output "eso_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = aws_iam_role.eso_role.arn
}

output "eso_role_name" {
  description = "Name of the IAM role for External Secrets Operator"
  value       = aws_iam_role.eso_role.name
}

output "eso_policy_arn" {
  description = "ARN of the IAM policy for External Secrets Operator"
  value       = aws_iam_policy.eso_secrets_policy.arn
}

output "eso_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  value       = helm_release.external_secrets.namespace
}

output "eso_chart_version" {
  description = "Version of External Secrets Operator chart installed"
  value       = helm_release.external_secrets.version
}

output "aws_account_id" {
  description = "AWS Account ID where ESO is deployed"
  value       = data.aws_caller_identity.current.account_id
}