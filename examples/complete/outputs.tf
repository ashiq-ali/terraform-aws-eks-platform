output "cluster_name"        { value = module.eks.cluster_name }
output "cluster_endpoint"    { value = module.eks.cluster_endpoint; sensitive = true }
output "vpc_id"              { value = module.vpc.vpc_id }
output "db_secret_arn"       { value = module.rds.secret_arn }
output "github_actions_role" { value = module.github_oidc.role_arn }
output "kubeconfig_command"  {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
