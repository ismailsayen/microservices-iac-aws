resource "aws_service_discovery_private_dns_namespace" "this" {
  name = var.namespace_name
  vpc = var.vpc_id
}


