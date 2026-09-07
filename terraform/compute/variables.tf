variable "ecs_service_names" {
  type      = list(string)
  sensitive = false
  default = [
    "api-gateway",
    "rabbitmq",
    "inventory-db",
    "inventory-app",
    "billing-db",
    "billing-app"
  ]
}
