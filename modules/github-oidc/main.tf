data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? (
    aws_iam_openid_connect_provider.github[0].arn
  ) : var.existing_oidc_provider_arn

  # Allow both branch pushes and PR workflows
  subject_conditions = concat(
    ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"],
    var.allow_pull_requests ? ["repo:${var.github_org}/${var.github_repo}:pull_request"] : []
  )
}

resource "aws_iam_role" "github_actions" {
  name        = var.iam_role_name
  description = "Assumed by GitHub Actions via OIDC — ${var.github_org}/${var.github_repo}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = local.subject_conditions
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "custom" {
  count = length(var.allowed_actions) > 0 ? 1 : 0

  name = "${var.iam_role_name}-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = var.allowed_actions
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
