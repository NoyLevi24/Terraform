# modules/blueprint/eso/main.tf

# External Secrets Operator Helm Chart
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets-system"
  create_namespace = true
  version          = "0.9.11"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "webhook.port"
    value = "9443"
  }

  depends_on = [var.eks_dependency]
}

# IAM Policy for ESO
resource "aws_iam_policy" "eso_secrets_policy" {
  name        = "${var.project_name}-eso-secrets-policy"
  description = "Policy for External Secrets Operator to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:journai/*"
      }
    ]
  })

  tags = var.tags
}

# IAM Role for ESO Service Account
resource "aws_iam_role" "eso_role" {
  name = "${var.project_name}-eso-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = [
              "system:serviceaccount:dev-journai:external-secrets-sa",
              "system:serviceaccount:staging-journai:external-secrets-sa",
              "system:serviceaccount:prod-journai:external-secrets-sa"
            ]
          }
        }
      }
    ]
  })

  tags = var.tags
  
  depends_on = [helm_release.external_secrets]
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_secrets_policy.arn
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}