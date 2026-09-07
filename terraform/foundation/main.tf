module "secrets-manager" {
  source      = "../modules/secrets-manger"
  secret_name = "production-credentials"
  secret_values = {
    region                   = var.aws_region
    profile                  = var.aws_profile
    domain_name              = var.domain_name
    alb_domain_name          = var.alb_domain_name
    alert_email               = var.alert_email
    rabbitmq_envs            = var.rabbitmq_envs
    rabbitmq_attr            = var.rabbitmq_attr
    api_gateway_envs         = var.api_gateway_envs
    api_gateway_attr         = var.api_gateway_attr
    inventory_app_envs       = var.inventory_app_envs
    inventory_app_attr       = var.inventory_app_attr
    inventory_db_envs        = var.inventory_db_envs
    inventory_db_attr        = var.inventory_db_attr
    billing_app_envs         = var.billing_app_envs
    billing_app_attr         = var.billing_app_attr
    billing_db_envs          = var.billing_db_envs
    billing_db_attr          = var.billing_db_attr
    aws_region               = var.aws_region
    aws_profile              = var.aws_profile
    alb_custom_header_secret = var.alb_custom_header_secret
    environment              = var.environment
  }
}


module "my_vpc" {
  source      = "../modules/vpc"
  vpc_cidr    = "10.0.0.0/16"
  environment = var.environment

  public_subnets_cidr = [
    { cidr_block = "10.0.0.0/24", az = "eu-west-3a" },
    { cidr_block = "10.0.1.0/24", az = "eu-west-3b" }
  ]
  private_subnets_cidr = [
    { cidr_block = "10.0.2.0/24", az = "eu-west-3a" },
    { cidr_block = "10.0.3.0/24", az = "eu-west-3b" }
  ]
}


# ==========================================
# GLOBAL IAM SECURITY AND ROLES
# ==========================================
module "ecs_task_execution_role" {
  source = "../modules/ecs_task_role"
}

# ==========================================
# CLOUD WATCH LOG GROUP
# ==========================================

module "cloud_watch_log_group" {
  source            = "../modules/cloud_watch"
  log_group_name    = "/ecs/${var.environment}"
  retention_in_days = 7
}

module "ec2_execution_role" {
  source = "../modules/ec2_role"
}

# ==========================================
# ECS CLUSTER
# ==========================================
module "my_cluster" {
  source       = "../modules/ecs"
  cluster_name = "cluster"
  environment  = var.environment
}

# ==========================================
# CLOUD-MAP & SERVICE-DISCOVERY
# ==========================================
module "service_discovery_namespace" {
  source         = "../modules/cloud_map"
  namespace_name = "${var.environment}.local"
  vpc_id         = module.my_vpc.vpc_id
}

# ==========================================
# target_groups
# ==========================================

module "target_groups" {
  source   = "../modules/lb_target_group"
  for_each = local.target_groups_config

  # Valeurs communes fixes
  vpc_id                = module.my_vpc.vpc_id
  tg_protocol           = "HTTP"
  tg_target_type        = "ip"
  health_check_enabled  = true
  health_check_protocol = "HTTP"
  health_check_matcher  = "200"
  health_check_interval = 30
  health_check_timeout  = 5
  healthy_threshold     = 2
  unhealthy_threshold   = 3
  tg_name               = each.value.tg_name
  tg_port               = each.value.tg_port
  health_check_path     = each.value.health_check_path
}

# ==========================================
# CERTIFICAT MANAGER
# ==========================================

resource "aws_acm_certificate" "wildcard" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "wildcard-cert-ismailsayen-space"
  }
}

# ==========================================
# ROUTE53 ZONE
# ==========================================

resource "aws_route53_zone" "this" {
  name = var.domain_name
}

# ==========================================
# COGNITO USER POOL && API GATEWAY && API GATEWAY AUTHORIZER
# ==========================================

module "cognito" {
  source = "../modules/cognito"
  user_pool_name="${var.environment}-user-pool"
  recovery_mechanism_priority=1
  cognito_domain_prefix="${var.environment}-test"
}

module "amazon-api-gateway" {
  source = "../modules/api_gateway"
  api_name = "my-api-gateway-${var.environment}"
}

module "api_gateway_authorizer" {
  source = "../modules/api_gateway_authorizer"
  agw_id = module.amazon-api-gateway.agw_id
  aws_region = var.aws_region
  user_pool_id = module.cognito.user_pool_id
  user_pool_client_id  = module.cognito.user_pool_client_id
}


module "api_gateway_integration" {
  source = "../modules/api_gateway_integration"
  alb_dns_name = "${var.alb_domain_name}.${var.domain_name}"
  alb_custom_header_secret = var.alb_custom_header_secret
  agw_id = module.amazon-api-gateway.agw_id
  agw_authorizer_id = module.api_gateway_authorizer.agw_authorizer_id
}

resource "aws_apigatewayv2_domain_name" "api_custom_domain" {
  domain_name = "api.${var.domain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.wildcard.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = module.amazon-api-gateway.agw_id
  domain_name = aws_apigatewayv2_domain_name.api_custom_domain.id
  stage       = "$default" 
}


resource "aws_route53_record" "api_alias" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_custom_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_custom_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}