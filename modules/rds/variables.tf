variable "identifier"          { type = string }
variable "vpc_id"              { type = string }
variable "subnet_ids"          { type = list(string) }
variable "allowed_cidr_blocks" { type = list(string) }
variable "database_name"       { type = string; default = "platform" }
variable "db_username"         { type = string; default = "platformadmin" }
variable "instance_class"      { type = string; default = "db.t3.medium" }
variable "allocated_storage"   { type = number; default = 50 }
variable "multi_az"            { type = bool;   default = true }
variable "deletion_protection" { type = bool;   default = true }
variable "skip_final_snapshot" { type = bool;   default = false }
variable "tags"                { type = map(string); default = {} }
