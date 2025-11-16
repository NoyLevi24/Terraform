# iam-eso.tf
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = "journai-dev-cluster"
}

resource "aws_iam_policy" "eso_secrets_policy" {
  name        = "journai-eso-secrets-policy"
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
        Resource = "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:journai/*"
      }
    ]
  })
}

# Service Account עבור ESO
resource "aws_iam_role" "eso_role" {
  name = "journai-eso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = [
              "system:serviceaccount:dev-journai:external-secrets-sa",
              "system:serviceaccount:staging-journai:external-secrets-sa",
              "system:serviceaccount:prod-journai:external-secrets-sa"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_secrets_policy.arn
}

output "eso_role_arn" {
  value       = aws_iam_role.eso_role.arn
  description = "ARN of the ESO IAM role"
}