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
