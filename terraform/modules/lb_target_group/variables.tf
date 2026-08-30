variable "tg_name" {
  type        = string
}

variable "tg_port" {
  type        = number
}

variable "tg_protocol" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "tg_target_type" {
  type        = string
}

# Health Check Variables
variable "health_check_enabled" {
  type        = bool
}

variable "health_check_path" {
  type        = string
}

variable "health_check_protocol" {
  type        = string
}

variable "health_check_matcher" {
  type        = string
}

variable "health_check_interval" {
  type        = number
}

variable "health_check_timeout" {
  type        = number
}

variable "healthy_threshold" {
  type        = number
}

variable "unhealthy_threshold" {
  type        = number
}

