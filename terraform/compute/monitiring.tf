resource "aws_sns_topic" "microservices_alerts" {
  name = "microservices-cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.microservices_alerts.arn
  protocol  = "email"
  endpoint  = local.secret["alert_email"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_alarm" {
  for_each            = toset(var.ecs_service_names)
  alarm_name          = "${local.secret["environment"]}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert if the container/service ${each.key} exceeds 80% CPU usage."
  alarm_actions       = [aws_sns_topic.microservices_alerts.arn]

  dimensions = {
    ClusterName = data.terraform_remote_state.foundation.outputs.cluster_name
    ServiceName = each.key
  }
}


resource "aws_cloudwatch_metric_alarm" "service_ram_alarm" {
  for_each            = toset(var.ecs_service_names)
  alarm_name          = "${local.secret["environment"]}-${each.key}-high-ram"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert if the container/service ${each.key} exceeds 85% memory usage."
  alarm_actions       = [aws_sns_topic.microservices_alerts.arn]

  dimensions = {
    ClusterName = data.terraform_remote_state.foundation.outputs.cluster_name
    ServiceName = each.key
  }
}


resource "aws_cloudwatch_dashboard" "microservices_ecs_dashboard" {
  dashboard_name = "${local.secret["environment"]}-Microservices-Containers-Health"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 8
        properties = {
          metrics = [
            for service in var.ecs_service_names : [
              "AWS/ECS", "CPUUtilization", "ServiceName", service, "ClusterName", data.terraform_remote_state.foundation.outputs.cluster_name, { "label": service }
            ]
          ]
          period = 300
          region = local.secret["aws_region"]
          title  = "CPU Consumption per Container / Service (%)"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 8
        properties = {
          metrics = [
            for service in var.ecs_service_names : [
              "AWS/ECS", "MemoryUtilization", "ServiceName", service, "ClusterName", data.terraform_remote_state.foundation.outputs.cluster_name, { "label": service }
            ]
          ]
          period = 300
          region = local.secret["aws_region"]
          title  = "RAM Consumption per Container / Service (%)"
          yAxis  = { left = { min = 0, max = 100 } }
        }
      }
    ]
  })
}