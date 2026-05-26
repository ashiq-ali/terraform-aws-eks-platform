# terraform-aws-eks-platform

Production-ready modular Terraform for a complete AWS EKS platform. Each module is independently usable; the `examples/complete` directory wires them into a full working cluster.

## Architecture

```
                        ┌─────────────────────────────────────────┐
                        │                  VPC                     │
                        │  ┌─────────────┐   ┌─────────────────┐  │
                        │  │ Public nets  │   │  Private nets   │  │
                        │  │ (ALB, NAT)  │   │ (EKS, RDS)      │  │
                        │  └──────┬──────┘   └────────┬────────┘  │
                        └─────────┼────────────────────┼──────────┘
                                  │                    │
              ┌───────────────────▼──┐    ┌────────────▼───────────┐
              │   AWS Load Balancer  │    │       EKS Cluster       │
              │   Controller (ALB)   │    │  ┌──────┐  ┌────────┐  │
              └──────────────────────┘    │  │System│  │Workers │  │
                                          │  │nodes │  │(Spot)  │  │
              ┌───────────────────────┐   │  └──────┘  └────────┘  │
              │   RDS PostgreSQL      │   └────────────────────────┘
              │   (Multi-AZ, private) │
              └───────────────────────┘
              ┌───────────────────────┐
              │  GitHub OIDC Role     │   ← CI/CD assumes role — no
              │  (no long-lived keys) │     long-lived AWS keys
              └───────────────────────┘
```

## Modules

| Module | Description |
|---|---|
| `vpc` | VPC, public/private subnets across 2 AZs, NAT Gateways, Flow Logs |
| `eks` | EKS cluster, managed node groups, IRSA, core add-ons |
| `rds` | RDS PostgreSQL, Multi-AZ, Secrets Manager, parameter group |
| `alb` | AWS Load Balancer Controller, IngressClass |
| `github-oidc` | OIDC federation for GitHub Actions — zero long-lived credentials |

## Quickstart

```bash
# 1. Clone and enter examples
git clone https://github.com/ashiq-ali/terraform-aws-eks-platform
cd terraform-aws-eks-platform/examples/complete

# 2. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit: region, cluster_name, account_id, github_repo

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with sufficient IAM permissions
- kubectl

## Module Usage

### VPC

```hcl
module "vpc" {
  source = "github.com/ashiq-ali/terraform-aws-eks-platform//modules/vpc"

  name               = "my-platform"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-2a", "eu-west-2b"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
  public_subnets     = ["10.0.1.0/24",  "10.0.2.0/24"]
  cluster_name       = "my-cluster"
}
```

### EKS

```hcl
module "eks" {
  source = "github.com/ashiq-ali/terraform-aws-eks-platform//modules/eks"

  cluster_name       = "my-cluster"
  cluster_version    = "1.30"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  system_node_instance_type  = "t3.medium"
  worker_node_instance_types = ["t3.medium", "t3a.medium"]
  worker_node_min_size       = 0
  worker_node_max_size       = 10
}
```

### RDS

```hcl
module "rds" {
  source = "github.com/ashiq-ali/terraform-aws-eks-platform//modules/rds"

  identifier          = "platform-db"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [module.vpc.vpc_cidr]
  instance_class      = "db.t3.medium"
  database_name       = "platform"
}
```

### GitHub OIDC

```hcl
module "github_oidc" {
  source = "github.com/ashiq-ali/terraform-aws-eks-platform//modules/github-oidc"

  github_org        = "my-org"
  github_repo       = "my-repo"
  iam_role_name     = "github-actions-deploy"
  allowed_actions   = ["eks:*", "ecr:*", "s3:GetObject"]
}
```

## Security

- EKS nodes in private subnets — no direct internet access
- IRSA for all AWS service account permissions — no node-level over-provisioning
- RDS accepts traffic only from the EKS cluster security group
- GitHub Actions uses OIDC — no AWS keys stored in GitHub Secrets
- KMS encryption for EKS secrets at rest
- VPC Flow Logs to CloudWatch for audit

## CI/CD

Every pull request runs:
- `terraform fmt -check`
- `terraform validate`
- `terraform plan` (posted as PR comment)

Merge to `main` triggers `terraform apply` via GitHub Actions with OIDC role assumption.

## Certifications behind this design

- **AWS Certified Solutions Architect – Professional** — multi-AZ, IRSA, least-privilege IAM
- **HashiCorp Terraform Associate** — module structure, remote state, provider pinning
- **CKA / CKS** — node group design, network isolation, secrets handling
