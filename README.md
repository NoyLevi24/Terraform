# JournAI Infrastructure as Code

This repository contains Terraform configurations for deploying and managing the JournAI application infrastructure on AWS.

## Overview

The infrastructure includes:
- VPC with public and private subnets
- EKS cluster for container orchestration
- RDS PostgreSQL database
- S3 buckets for storage
- IAM roles and policies
- Security groups and networking

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- kubectl (for EKS cluster interaction)
- AWS IAM Authenticator

## Directory Structure

```
.
├── README.md            # This file
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable declarations
├── outputs.tf           # Output values
├── providers.tf         # Provider configurations
├── versions.tf          # Version constraints
├── terraform.tfvars     # Variable values
└── modules/             # Reusable modules
    ├── blueprint/       # EKS add-ons
    │   ├── argocd/              # ArgoCD for GitOps
    │   ├── aws-load-balancer-controller/  # ALB Controller
    │   ├── karpenter/           # Karpenter for node autoscaling
    │   └── kube-prometheus-stack/ # Monitoring
    ├── eks/             # EKS cluster module
    ├── rds/             # RDS database module
    ├── s3/              # S3 bucket module
    └── vpc/             # VPC and networking module
```

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Create a `terraform.tfvars` file with your configuration:
   ```hcl
   environment = "dev"
   region     = "us-east-1"
   project_name = "journai"
   ```

4. Review the execution plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Modules

### EKS Cluster
Manages the Elastic Kubernetes Service cluster and node groups.

### RDS
Sets up a PostgreSQL database with:
- Multi-AZ deployment (in production)
- Automated backups
- Monitoring
- Security groups

### VPC
Creates a VPC with:
- Public and private subnets
- NAT gateways
- Route tables
- Internet gateway

### S3
Manages S3 buckets for application storage.

## Security

- All resources are tagged with environment and project name
- IAM roles follow the principle of least privilege
- Database has encryption at rest enabled
- Security groups are configured to allow only necessary traffic

## Best Practices

- Use workspaces for managing different environments
- Never commit sensitive values to version control
- Use remote state with locking (e.g., S3 backend)
- Regularly update module versions

## Variables

Key variables can be found in `variables.tf`. Required variables include:

- `project_name` - Name of the project (used for resource naming)
- `environment` - Deployment environment (dev/staging/prod)
- `region` - AWS region
- `vpc_cidr` - CIDR block for the VPC
- `private_subnets` - List of private subnet CIDRs
- `public_subnets` - List of public subnet CIDRs

## Outputs

Important outputs include:
- EKS cluster endpoint
- RDS endpoint
- S3 bucket names
- VPC and subnet IDs

## Clean Up

To destroy all resources:
```bash
terraform destroy
```


