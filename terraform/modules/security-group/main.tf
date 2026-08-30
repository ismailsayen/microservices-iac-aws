resource "aws_security_group" "my_vpc_sg" {
  name        = var.security_group_name
  description = "Security group for my VPC"
  vpc_id      = var.vpc_id
}

# 1. Règles Ingress basées sur Security Group
resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each = { for idx, rule in var.ingress_rules_sg : idx => rule }

  security_group_id            = aws_security_group.my_vpc_sg.id
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  referenced_security_group_id = each.value.source_sg
}

# 2. Règles Ingress basées sur CIDR IP
resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each = { for idx, rule in var.ingress_rules_cidr : idx => rule }

  security_group_id = aws_security_group.my_vpc_sg.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
  cidr_ipv4         = each.value.cidr_ipv4
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.my_vpc_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
