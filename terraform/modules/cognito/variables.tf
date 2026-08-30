variable "user_pool_name" {
  type        = string
}

variable "recovery_mechanism_priority" {
  type        = number
  default     = 1
}

variable "cognito_domain_prefix" {
  type        = string
}

variable "cognito_client_name" {
  type        = string
  default     = "my-app-client"
}

variable "cognito_callback_urls" {
  type        = list(string)
  default     = ["https://example.com/"]
}

variable "cognito_logout_urls" {
  type        = list(string)
  default     = ["https://example.com/"]
}