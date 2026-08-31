# ==============================================================================
# SERVICE 1 : API-GATEWAY
# ==============================================================================

module "api_gateway_task" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-api-gateway"
  service_name = local.secret["api_gateway_attr"].service_name
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "api_gateway"
  container_image  = "isayen/api-gateway-app:v1.3"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    {
      name          = local.secret["api_gateway_attr"].port_name,
      containerPort = local.secret["api_gateway_attr"].service_port,
      hostPort      = local.secret["api_gateway_attr"].service_port,
      protocol      = "tcp"
    }
  ]

  environment_variables = local.secret["api_gateway_envs"]
  cluster_id            = data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn
  security_group_id      = data.terraform_remote_state.foundation.outputs.agw-sg-id
  subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["api_gateway_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["api_gateway_attr"].service_port
  port_name              = local.secret["api_gateway_attr"].port_name
  dns_name               = local.secret["api_gateway_attr"].dns_name
  services_to_wait       = [module.rabbitmq_task.service_arn, module.billing-app.service_arn, module.inventory-app.service_arn]
  target_group_arn       = data.terraform_remote_state.foundation.outputs.agw-tg-arn
  ALB_port               = local.secret["api_gateway_attr"].service_port
}

# ==============================================================================
# SERVICE 2 : RABBITMQ
# ==============================================================================

module "rabbitmq_task" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-rabbit-mq"
  service_name = local.secret["rabbitmq_attr"].service_name
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "rabbit_mq"
  container_image  = "isayen/rabbit-queue:v1.1"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    { name = local.secret["rabbitmq_attr"].port_name, containerPort = local.secret["rabbitmq_attr"].service_port, hostPort = local.secret["rabbitmq_attr"].service_port, protocol = "tcp" },
    { 
    name          = "rabbitmq-mgmt", 
    containerPort = 15672, 
    hostPort      = 15672, 
    protocol      = "tcp" 
  }
  ]

  environment_variables = local.secret["rabbitmq_envs"]
  cluster_id            =  data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn

  security_group_id      = data.terraform_remote_state.foundation.outputs.alb_sg-id  //#################################################
  subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["rabbitmq_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["rabbitmq_attr"].service_port
  port_name              = local.secret["rabbitmq_attr"].port_name
  dns_name               = local.secret["rabbitmq_attr"].dns_name
  services_to_wait       = []
  target_group_arn       = data.terraform_remote_state.foundation.outputs.rabbitmq-tg-arn
  ALB_port               = 15672
}

# ==============================================================================
# SERVICE 3 : INVENTORY-APP && INVENTORY-DB
# ==============================================================================

module "inventory-db" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-inventory-db"
  service_name = local.secret["inventory_db_attr"].service_name  
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "inventory-db"
  container_image  = "helouazizi2001/inventory-database"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    { name = local.secret["inventory_db_attr"].port_name, containerPort = local.secret["inventory_db_attr"].service_port, hostPort = local.secret["inventory_db_attr"].service_port, protocol = "tcp" }
  ]

  environment_variables = local.secret["inventory_db_envs"]
  cluster_id            = data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn
  security_group_id      = data.terraform_remote_state.foundation.outputs.inventory-db-sg-id
   subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["api_gateway_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["inventory_db_attr"].service_port
  port_name              = local.secret["inventory_db_attr"].port_name
  dns_name               = local.secret["inventory_db_attr"].dns_name
  services_to_wait       = []
}


module "inventory-app" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-inventory-app"
  service_name = local.secret["inventory_app_attr"].service_name  
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "inventory-app"
  container_image  = "isayen/inventory-app:v1.0"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    { name = local.secret["inventory_app_attr"].port_name, containerPort = local.secret["inventory_app_attr"].service_port, hostPort = local.secret["inventory_app_attr"].service_port, protocol = "tcp" }
  ]

  environment_variables = local.secret["inventory_app_envs"] 
  cluster_id            = data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn
  security_group_id      = data.terraform_remote_state.foundation.outputs.inventory-app-sg-id 
  subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids 
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["api_gateway_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["inventory_app_attr"].service_port
  port_name              = local.secret["inventory_app_attr"].port_name
  dns_name               = local.secret["inventory_app_attr"].dns_name
  services_to_wait       = [module.inventory-db.service_arn]
}


module "billing-db" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-billing-db"
  service_name = local.secret["billing_db_attr"].service_name 
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "billing-db"
  container_image  = "helouazizi2001/billing-database"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    { name = local.secret["billing_db_attr"].port_name, containerPort = local.secret["billing_db_attr"].service_port, hostPort = local.secret["billing_db_attr"].service_port, protocol = "tcp" }
  ]

  environment_variables = local.secret["billing_db_envs"]
  cluster_id            = data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn
  security_group_id      = data.terraform_remote_state.foundation.outputs.billing-db-sg-id 
  subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids 
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["billing_db_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["billing_db_attr"].service_port
  port_name              = local.secret["billing_db_attr"].port_name
  dns_name               = local.secret["billing_db_attr"].dns_name
  services_to_wait       = []
}


module "billing-app" {
  source       = "../modules/ecs_task_definition"
  environment  = "${local.secret["environment"]}-billing-app"
  service_name = local.secret["billing_app_attr"].service_name 
  network_mode = "awsvpc"
  cpu          = 128
  memory       = 256

  container_name   = "billing-app"
  container_image  = "isayen/billing-app:v1.1"
  container_cpu    = 128
  container_memory = 256

  port_mappings = [
    { name = local.secret["billing_app_attr"].port_name, containerPort = local.secret["billing_app_attr"].service_port, hostPort = local.secret["billing_app_attr"].service_port, protocol = "tcp" }
  ]

  environment_variables = local.secret["billing_app_envs"]
  cluster_id            = data.terraform_remote_state.foundation.outputs.cluster_id
  execution_role_arn    = data.terraform_remote_state.foundation.outputs.ecs_task_execution_role_arn
  security_group_id      = data.terraform_remote_state.foundation.outputs.billing-app-sg-id 
  subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids 
  log_group_name         = data.terraform_remote_state.foundation.outputs.log_group_name
  log_prefix             = "/ecs/${local.secret["billing_db_attr"].service_name}"
  aws_region             = local.secret["region"]
  service_discovery_arn  = data.terraform_remote_state.foundation.outputs.service_discovery_namespace_arn
  capacity_provider_name = module.ecs_capacity_provider.capacity_provider_name 
  service_port           = local.secret["billing_app_attr"].service_port
  port_name              = local.secret["billing_app_attr"].port_name
  dns_name               = local.secret["billing_app_attr"].dns_name
  services_to_wait = [
    module.billing-db.service_arn,
    module.rabbitmq_task.service_arn
  ]
}
