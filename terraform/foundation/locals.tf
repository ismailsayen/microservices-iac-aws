locals {
  target_groups_config = {
    "api-gateway" = {
      tg_name           = "api-gateway-tg"
      tg_port           = var.api_gateway_attr.service_port
      health_check_path = "/api/health",
      
    },
    "rabbitmq-dashboard" = {
      tg_name           = "rabbitmq-dashboard-tg"
      tg_port           = 15672
      health_check_path = "/"
    }
  }
}