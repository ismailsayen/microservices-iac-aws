variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string 
}

variable "instance_type" {
  description = "The EC2 instance type for the ECS instances"
  type        = string
}

variable "desired_capacity" {
  description = "The desired number of ECS instances in the Auto Scaling group"
  type        = number
}

variable "max_size" {
  description = "The maximum number of ECS instances in the Auto Scaling group"
  type        = number
}

variable "min_size" {
  description = "The minimum number of ECS instances in the Auto Scaling group"
  type        = number
}


variable "subnet_ids" {
  description = "A list of subnet IDs for the Auto Scaling group"
  type        = list(string)
}
variable "ecs_cluster_name" {
  description = "The name of the ECS cluster to join"
  type        = string
}

variable "ecs_instance_profile_arn" {
  description = "The ARN of the IAM instance profile for ECS instances"
  type        = string
}

variable "security-grp" {
  type = string
}