variable "alb_dns_name" {
  type = string
}

variable "alb_custom_header_secret" {
  type = string
  sensitive = true
}

variable "agw_id" {
  type = string
}

variable "agw_authorizer_id" {
  type = string
}
