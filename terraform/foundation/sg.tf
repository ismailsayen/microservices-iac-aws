module "alb_sg" {
  source              = "../modules/security-group"
  security_group_name = "alb-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_cidr = [
    { from_port = 80, to_port = 80, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
    { from_port = 433, to_port = 433, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" },
    { from_port = 15672, to_port = 15672, ip_protocol = "tcp", cidr_ipv4 = "0.0.0.0/0" }
  ]
}


module "ec2_sg" {
  source              = "../modules/security-group"
  security_group_name = "ssh-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_cidr = [
    { from_port = 22, to_port = 22, ip_protocol = "tcp",cidr_ipv4 = "0.0.0.0/0"  }
  ]
}

module "api_gateway_sg" {
  source              = "../modules/security-group"
  security_group_name = "api-gateway-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg  = [
    { from_port = var.api_gateway_attr.service_port, to_port = var.api_gateway_attr.service_port, ip_protocol = "tcp", source_sg = module.alb_sg.sg-id }
  ]
}


module "rabbitmq_sg" {
  source              = "../modules/security-group"
  security_group_name = "rabbitmq-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg = [
    { from_port = var.rabbitmq_attr.service_port, to_port = var.rabbitmq_attr.service_port, ip_protocol = "tcp", source_sg = module.api_gateway_sg.sg-id },
    { from_port = var.rabbitmq_attr.service_port, to_port = var.rabbitmq_attr.service_port, ip_protocol = "tcp", source_sg = module.billing-app-sg.sg-id },
    { from_port = 15672, to_port = 15672, ip_protocol = "tcp", source_sg = module.alb_sg.sg-id }

  ]
}


module "inventory-db-sg" {
  source              = "../modules/security-group"
  security_group_name = "inventory-app-db"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg = [
    { from_port = var.inventory_db_attr.service_port, to_port = var.inventory_db_attr.service_port, ip_protocol = "tcp", source_sg = module.inventory-app-sg.sg-id }
  ]
}


module "inventory-app-sg" {
  source              = "../modules/security-group"
  security_group_name = "inventory-app-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg = [
    { from_port = var.inventory_app_attr.service_port, to_port = var.inventory_app_attr.service_port, ip_protocol = "tcp", source_sg = module.api_gateway_sg.sg-id }
  ]
}


module "billing-db-sg" {
  source              = "../modules/security-group"
  security_group_name = "billing-app-db"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg = [
    { from_port = var.billing_db_attr.service_port, to_port = var.billing_db_attr.service_port, ip_protocol = "tcp", source_sg = module.billing-app-sg.sg-id }
  ]
}


module "billing-app-sg" {
  source              = "../modules/security-group"
  security_group_name = "billing-app-sg"
  vpc_id              = module.my_vpc.vpc_id
  ingress_rules_sg       = [
    {
      from_port = var.billing_app_attr.service_port,
      to_port = var.billing_app_attr.service_port,
      ip_protocol = "tcp",
      source_sg = module.api_gateway_sg.sg-id
    }
  ]
}