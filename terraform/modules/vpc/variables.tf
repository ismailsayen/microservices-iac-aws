variable "vpc_cidr" {
  type        = string
  description = "Plage d'adresses CIDR pour le VPC"
}

variable "public_subnets_cidr" {
  type        = list(object({
    cidr_block = string
    az         = string
  }))
  description = "CIDR pour le subnet public"
}

variable "private_subnets_cidr" {
  type        = list(object({
    cidr_block = string
    az         = string
  }))
  description = "CIDR pour le subnet privé"
}

variable "environment" {
  type        = string
  description = "Nom de l'environnement (ex: dev, prod)"
  default     = "dev"
}

