locals {
    secret = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)
}

locals {
  ecs_service_names = [
    local.secret["api_gateway_attr"].service_name,
    local.secret["rabbitmq_attr"].service_name,
    local.secret["inventory_db_attr"].service_name,
    local.secret["inventory_app_attr"].service_name,
    local.secret["billing_db_attr"].service_name,
    local.secret["billing_app_attr"].service_name
  ]
  
}