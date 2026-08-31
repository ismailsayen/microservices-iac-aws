data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.0.*-kernel-6.1-x86_64"]
  }
}

# resource "aws_key_pair" "this" {
#     key_name = "key-test"
#     public_key = file("/workspace/id_ed25519.pub")
# }

resource "aws_launch_template" "ecs_launch_template" {
  name_prefix   = "${var.environment}-ecs-launch-template-"
  image_id      = data.aws_ami.ecs_ami.id
  instance_type = var.instance_type
  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
              EOF
            )
  # key_name = aws_key_pair.this.key_name

 vpc_security_group_ids = [var.security-grp]

  iam_instance_profile {
    arn = var.ecs_instance_profile_arn
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = var.subnet_ids
  protect_from_scale_in = true
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  force_delete              = true
  tag {
    key                 = "Name"
    value               = "${var.environment}-ecs-instance"
    propagate_at_launch = true
  }
}