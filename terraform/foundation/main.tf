module "secrets-manager" {
  source      = "../modules/secrets-manger"
  secret_name = "production/credentials"
  secret_values = {
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