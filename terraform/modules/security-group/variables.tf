variable "vpc_id" {
  type = string
}

variable "ingress_rules_sg" {
  type = list(object({
    from_port   = number
    to_port     = number
    ip_protocol = string
    source_sg   = string
  }))
  default     = []
}

variable "ingress_rules_cidr" {
  type = list(object({
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
  }))
  default     = []
}
variable "security_group_name" {
  description = "The name of the security group"
  type        = string
}
