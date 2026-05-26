module "vpc" {
  source = "../../modules/vpc"

  name               = var.cluster_name
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]
  cluster_name       = var.cluster_name
  enable_flow_logs   = true
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = "1.30"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  system_node_instance_type  = "t3.medium"
  system_node_min_size       = 2
  system_node_desired_size   = 2
  system_node_max_size       = 4

  worker_node_instance_types = ["t3.medium", "t3a.medium"]
  worker_node_min_size       = 0
  worker_node_desired_size   = 2
  worker_node_max_size       = 10

  tags = local.tags
}

module "rds" {
  source = "../../modules/rds"

  identifier          = "${var.cluster_name}-db"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [module.vpc.vpc_cidr]
  database_name       = "platform"
  instance_class      = "db.t3.medium"
  multi_az            = var.environment == "prod"
  tags                = local.tags
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  github_org    = var.github_org
  github_repo   = var.github_repo
  iam_role_name = "${var.cluster_name}-github-actions"

  allowed_actions = [
    "eks:DescribeCluster",
    "ecr:GetAuthorizationToken",
    "ecr:BatchGetImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecr:PutImage",
    "s3:GetObject",
    "s3:PutObject",
  ]

  tags = local.tags
}

locals {
  tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
  }
}
