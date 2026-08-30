resource "aws_ecs_cluster" "this" {
  name = "${var.environment}-ecs-${var.cluster_name}"
}