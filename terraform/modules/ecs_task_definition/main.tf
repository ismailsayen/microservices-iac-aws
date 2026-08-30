resource "aws_ecs_task_definition" "this" {
    family="${var.environment}-ecs-task-definition"
    requires_compatibilities= ["EC2"]
    network_mode= var.network_mode
    memory= var.memory
    cpu= var.cpu
    execution_role_arn= var.execution_role_arn
    container_definitions= jsonencode([
        {
            name= var.container_name
            image= var.container_image
            cpu= var.container_cpu
            memory= var.container_memory
            essential= true
            portMappings= var.port_mappings
            environment= var.environment_variables
            logConfiguration= {
                logDriver= "awslogs"
                options = {
                    awslogs-group         = var.log_group_name
                    awslogs-region        = var.aws_region
                    awslogs-stream-prefix = var.log_prefix
                }
            }
        }
    ])
    
}
resource "aws_ecs_service" "this"{
    name = var.service_name
    cluster = var.cluster_id
    task_definition = aws_ecs_task_definition.this.arn
    desired_count = 1
    capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 1
    base              = 0
  }
    
    network_configuration {
        subnets = var.subnet_ids
        security_groups = [var.security_group_id]
    }

    service_connect_configuration {
      enabled = true
      namespace = var.service_discovery_arn
      service {
        port_name = var.port_name
        discovery_name = var.service_name
        client_alias {
          port = var.service_port
          dns_name = var.service_name
        }
      }
    }

    depends_on = [var.services_to_wait]

    dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []

    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.ALB_port
    }
  }
}
