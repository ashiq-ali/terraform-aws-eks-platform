variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node groups"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint (set false for stricter security)"
  type        = bool
  default     = true
}

variable "system_node_instance_type" {
  description = "Instance type for system node group (on-demand)"
  type        = string
  default     = "t3.medium"
}

variable "system_node_desired_size" { type = number; default = 2 }
variable "system_node_min_size"     { type = number; default = 2 }
variable "system_node_max_size"     { type = number; default = 4 }

variable "worker_node_instance_types" {
  description = "Instance types for worker node group (spot)"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "worker_node_desired_size" { type = number; default = 2 }
variable "worker_node_min_size"     { type = number; default = 0 }
variable "worker_node_max_size"     { type = number; default = 10 }

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
