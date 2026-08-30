variable "alb_name" {
  type        = string
}

variable "alb_internal" {
  type        = bool
}

variable "load_balancer_type" {
  type        = string
}

variable "enable_deletion_protection" {
  type        = bool
}

variable "alb_security_group_ids" {
  type        = list(string)
}

variable "alb_subnet_ids" {
  type        = list(string)
}

variable "listener_rules" {
  type = map(object({
    priority         = number
    target_group_arn = string
    listener_key     = string
    # Conditions optionnelles
    header_condition = optional(object({
      name   = string
      values = list(string)
    }))
    
    path_condition = optional(object({
      values = list(string)
    }))
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    port     = number
    protocol = string
    arn      = optional(string)
  }))
  default = {}
}

