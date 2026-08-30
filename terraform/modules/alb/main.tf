resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = var.alb_internal
  load_balancer_type = var.load_balancer_type
  security_groups    = var.alb_security_group_ids
  subnets            = var.alb_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection

}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  dynamic "default_action" {
    for_each = each.value.arn != null ? [each.value.arn] : []
    content {
      type             = "forward"
      target_group_arn = each.value.arn
    }
  }

  dynamic "default_action" {
    for_each = each.value.arn == null ? [1] : []
    content {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "Access Denied: Direct access to ALB is not allowed."
        status_code  = "403"
      }
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each     = var.listener_rules
  listener_arn =  aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority

 dynamic "condition" {
    for_each = each.value.header_condition != null ? [each.value.header_condition] : []
    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }


  dynamic "condition" {
    for_each = each.value.path_condition != null ? [each.value.path_condition] : []
    content {
      path_pattern {
        values = condition.value.values
      }
    }
  }

  action {
  type             = "forward"
  target_group_arn = each.value.target_group_arn  
  }
}