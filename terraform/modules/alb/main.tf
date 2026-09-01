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

  ssl_policy      = lookup(each.value, "ssl_policy", null)
  certificate_arn = lookup(each.value, "certificate_arn", null)
  dynamic "default_action" {
    for_each = each.value.arn != null ? [each.value.arn] : []
    content {
      type             = "forward"
      target_group_arn = each.value.arn
    }
  }

  # Action 2: Redirection HTTP (80) vers HTTPS (443)
  dynamic "default_action" {
    for_each = lookup(each.value, "action_type", null) == "redirect" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # Action 3: Fixed Response 403 par défaut (ex: 443)
  dynamic "default_action" {
    for_each = lookup(each.value, "action_type", null) == "fixed-response" ? [1] : []
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