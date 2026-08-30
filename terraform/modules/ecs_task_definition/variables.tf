variable "environment" {
  description = "The environment name for the ECS task definition."
  type        = string
}

variable "network_mode" {
  description = "The network mode for the ECS task definition."
  type        = string
}

                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
variable "environment_variables" {
  description = "A map of environment variables to set in the ECS task definition."
  type        = list(object({
    name  = string
    value = string
  }))
}

variable "container_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "container_cpu" {
  type = number
}

variable "container_memory" {
  type = number
}
variable "port_mappings" {
  description = "A list of port mappings for the ECS task definition."
  type        = list(object({
    name          = string
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
}

variable "service_name" {
  description = "The name of the ECS service."
  type        = string
}

variable "cluster_id" {
  description = "The ID of the ECS cluster where the service will be deployed."
  type        = string
}


variable "execution_role_arn" {
  description = "The ARN of the IAM role that the ECS task will use for execution."
  type        = string
}


variable "subnet_ids" {
  description = "A list of subnet IDs for the ECS service."
  type        = list(string)
}

variable "security_group_id" {
  description = "The ID of the security group for the ECS service."
  type        = string
}

variable "log_group_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "log_prefix" {
  type = string
}

variable "service_discovery_arn" {
  type = string
}

variable "capacity_provider_name" {
  type = string
}

variable "port_name" {
  type = string
}

variable "service_port" {
  type = number
}

variable "dns_name" {
  type = string
}

variable "services_to_wait" {
  type= list(any)
  default = []
}

variable "target_group_arn" {
  type        = string
  default     = null
}

variable "ALB_port" {
  type = number
  default = null
}