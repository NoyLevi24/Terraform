# JournAI Infrastructure as Code

This repository contains Terraform configurations for deploying and managing the JournAI application infrastructure on AWS.

## Overview

The infrastructure includes:
- VPC with public and private subnets
- EKS cluster for container orchestration
- RDS PostgreSQL database
- S3 buckets for storage
- AWS Secrets Manager for secure secrets storage
- External Secrets Operator for automatic secret injection
- IAM roles and policies
- Security groups and networking
- ArgoCD for GitOps automation
- Monitoring with Prometheus and Grafana

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- kubectl (for EKS cluster interaction)
- AWS IAM Authenticator

## Directory Structure

```
.
├── README.md            # This file
├── environments/         # Environment-specific configurations
│   ├── dev/            # Development environment
│   │   ├── eks.tfvars
│   │   ├── networking.tfvars
│   │   └── storage_db.tfvars
│   ├── staging/        # Staging environment
│   └── prod/           # Production environment
├── infrastructure/      # Infrastructure components
│   ├── eks/            # EKS cluster configuration
│   ├── networking/     # VPC and networking
│   └── storage-db/     # RDS and S3 storage
└── modules/             # Reusable modules
    ├── blueprint/       # EKS add-ons and services
    │   ├── argocd/              # ArgoCD for GitOps
    │   ├── aws-load-balancer-controller/  # ALB Controller
    │   ├── eso/                 # External Secrets Operator
    │   ├── karpenter/           # Karpenter for node autoscaling
    │   └── kube-prometheus-stack/ # Monitoring
    ├── eks/             # EKS cluster module
    ├── rds/             # RDS database module
    ├── s3/              # S3 bucket module
    └── vpc/             # VPC and networking module
```

## Getting Started

### Deployment Order

Deploy infrastructure components in the following order:

1. **Networking** (VPC, subnets, security groups)
2. **Storage & Database** (S3 buckets, RDS database)
3. **EKS Cluster** (Kubernetes control plane and node groups)
4. **EKS Add-ons** (ArgoCD, External Secrets Operator, monitoring)

### Step-by-Step Deployment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/NoyLevi24/Terraform.git
   cd terraform
   ```

2. **Deploy Networking:**
   ```bash
   cd infrastructure/networking
   terraform init
   terraform plan -var-file="../../environments/dev/networking.tfvars"
   terraform apply -var-file="../../environments/dev/networking.tfvars"
   ```

3. **Deploy Storage & Database:**
   ```bash
   cd ../storage-db
   terraform init
   terraform plan -var-file="../../environments/dev/storage_db.tfvars"
   terraform apply -var-file="../../environments/dev/storage_db.tfvars"
   ```

4. **Deploy EKS Cluster:**
   ```bash
   cd ../eks
   terraform init
   terraform plan -var-file="../../environments/dev/eks.tfvars"
   terraform apply -var-file="../../environments/dev/eks.tfvars"
   ```

### Environment Configuration

Each environment has its own `.tfvars` files in the `environments/` directory:

- `environments/dev/` - Development environment
- `environments/staging/` - Staging environment  
- `environments/prod/` - Production environment

## Modules

### EKS Cluster
Manages the Elastic Kubernetes Service cluster and node groups with:
- Managed node groups with auto-scaling
- IAM roles for service accounts (IRSA)
- Integration with AWS Load Balancer Controller
- External Secrets Operator deployment
- ArgoCD for GitOps automation
- Monitoring with Prometheus and Grafana

### RDS
Sets up a PostgreSQL database with:
- Multi-AZ deployment (in production)
- Automated backups
- Monitoring
- Security groups
- Encryption at rest and in transit

### VPC
Creates a VPC with:
- Public and private subnets
- NAT gateways
- Route tables
- Internet gateway
- Security groups

### S3
Manages S3 buckets for application storage with:
- Encryption
- Versioning
- Lifecycle policies
- Security policies

### Blueprint Modules
These modules deploy Kubernetes add-ons and services:

#### ArgoCD
Deploys ArgoCD for GitOps automation with:
- Application sets for multi-environment deployments
- Automatic sync policies
- Integration with external repositories

#### External Secrets Operator
Deploys the External Secrets Operator with:
- AWS Secrets Manager integration
- IAM roles for secure secret access
- Automatic secret synchronization
- Support for multiple environments

#### AWS Load Balancer Controller
Manages AWS load balancers with:
- Application Load Balancer support
- Network Load Balancer support
- Ingress controller integration
- SSL/TLS termination

#### Kube Prometheus Stack
Provides monitoring and observability with:
- Prometheus metrics collection
- Grafana dashboards
- AlertManager for alerting
- Custom metrics for JournAI applications

## Security

JournAI infrastructure follows AWS security best practices:

- **All resources are tagged** with environment and project name for proper governance
- **IAM roles follow the principle of least privilege** with minimal required permissions
- **Database encryption** at rest and in transit with AWS KMS
- **Security groups** configured to allow only necessary traffic
- **AWS Secrets Manager** for secure storage and automatic rotation of sensitive data
- **External Secrets Operator** with IRSA for secure secret access without long-lived credentials
- **Private subnets** for application workloads to limit exposure
- **VPC flow logs** and CloudTrail for audit and monitoring
- **S3 encryption** with server-side encryption and bucket policies
- **EKS RBAC** for Kubernetes-level access control

## Best Practices

- **Use separate workspaces** for managing different environments (dev/staging/prod)
- **Never commit sensitive values** to version control - use AWS Secrets Manager
- **Use remote state with locking** (Terraform Cloud or S3 backend)
- **Regularly update module versions** for security and features
- **Implement proper tagging** for cost allocation and governance
- **Use IRSA (IAM Roles for Service Accounts)** instead of AWS keys in pods
- **Enable monitoring and logging** for all infrastructure components
- **Regular security audits** of IAM policies and security groups

## Variables

Key variables are defined in each component's `variables.tf` files. Required variables include:

- `project_name` - Name of the project (used for resource naming)
- `environment` - Deployment environment (dev/staging/prod)
- `aws_region` - AWS region for deployment
- `vpc_cidr` - CIDR block for the VPC
- `private_subnets` - List of private subnet CIDRs
- `public_subnets` - List of public subnet CIDRs
- `node_instance_types` - EKS node instance types
- `node_desired_capacity` - Desired number of nodes
- `node_min_capacity` - Minimum number of nodes
- `node_max_capacity` - Maximum number of nodes

## Outputs

Important outputs from each component:

### Networking
- VPC ID and CIDR blocks
- Subnet IDs (public and private)
- Security Group IDs
- Internet Gateway ID

### Storage & Database
- RDS endpoint and port
- RDS security group ID
- S3 bucket names
- Database credentials (stored in Secrets Manager)

### EKS Cluster
- EKS cluster endpoint
- Cluster certificate authority data
- Node group ARNs
- IAM role ARNs
- OIDC provider ARN

### Add-ons
- ArgoCD URL and credentials
- External Secrets Operator status
- Load Balancer Controller endpoints
- Monitoring endpoints (Prometheus/Grafana)

## Clean Up

To destroy all resources, follow the reverse order of deployment:

1. **Destroy EKS Cluster (this will remove add-ons):**
   ```bash
   cd infrastructure/eks
   terraform destroy -var-file="../../environments/dev/eks.tfvars"
   ```

2. **Destroy Storage & Database:**
   ```bash
   cd ../storage-db
   terraform destroy -var-file="../../environments/dev/storage_db.tfvars"
   ```

3. **Destroy Networking:**
   ```bash
   cd ../networking
   terraform destroy -var-file="../../environments/dev/networking.tfvars"
   ```

**Important:** Destroying resources will also delete:
- AWS Secrets Manager secrets
- S3 bucket contents (ensure backups are created)
- RDS databases (ensure final backups are taken)
- EKS clusters and all running applications

## Monitoring and Observability

The infrastructure includes comprehensive monitoring:

- **Prometheus** for metrics collection
- **Grafana** for visualization and dashboards
- **CloudWatch** for AWS resource monitoring
- **VPC Flow Logs** for network traffic analysis
- **CloudTrail** for API audit logging
- **RDS Enhanced Monitoring** for database performance

## Integration with GitOps

This Terraform configuration is designed to work seamlessly with the GitOps repository:

- **ArgoCD** is deployed automatically for application deployment
- **External Secrets Operator** syncs AWS Secrets Manager to Kubernetes
- **IAM roles** are configured for proper GitOps integration
- **Multi-environment support** with proper isolation

## Related Repositories

- **Application Code:** [JournAI](https://github.com/NoyLevi24/JournAI.git)
- **GitOps Configuration:** [GitOps](https://github.com/NoyLevi24/GitOps.git)

---

*Built with ❤️ using Terraform and AWS best practices*


