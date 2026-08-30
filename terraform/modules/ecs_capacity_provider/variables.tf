variable "auto_scaling_group_arn" {  
  description = "The ARN of the Auto Scaling group to associate with the ECS capacity provider"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster to associate with the capacity provider"
  type        = string
}