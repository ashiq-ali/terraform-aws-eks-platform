variable "github_org"                  { type = string }
variable "github_repo"                 { type = string }
variable "github_branch"               { type = string; default = "main" }
variable "iam_role_name"               { type = string }
variable "create_oidc_provider"        { type = bool; default = true }
variable "existing_oidc_provider_arn"  { type = string; default = "" }
variable "allow_pull_requests"         { type = bool; default = false }
variable "allowed_actions"             { type = list(string); default = [] }
variable "managed_policy_arns"         { type = list(string); default = [] }
variable "tags"                        { type = map(string); default = {} }
