variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}



variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
}

variable "rabbitmq_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "rabbitmq_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}

variable "api_gateway_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}

variable "api_gateway_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}


variable "inventory_app_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}
variable "inventory_app_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}

variable "inventory_db_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}
variable "inventory_db_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}


variable "billing_app_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}
variable "billing_app_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}


variable "billing_db_envs" {
  type = list(object({
    name  = string
    value = string
  }))
}
variable "billing_db_attr" {
  type = object({
    service_name = string,
    port_name    = string,
    service_port = number,
    dns_name     = string
  })
}

variable "alb_custom_header_secret" {
  type      = string
  sensitive = true
}

variable "environment" {
  default = "production"
}
