resource "aws_ecs_capacity_provider" "this" {
  name = "${var.environment}-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.auto_scaling_group_arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
    managed_draining = "DISABLED"
  }

  tags = {
    Name = "${var.environment}-ecs-capacity-provider"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = var.cluster_name
  capacity_providers = [
    aws_ecs_capacity_provider.this.name
  ]

 
}