module "auto_scaling" {
  source                   = "../modules/auto-scalling"
  environment              = local.secret["environment"]
  instance_type            = "t3.micro"
  desired_capacity         = 7
  max_size                 = 9
  min_size                 = 0
  subnet_ids               = data.terraform_remote_state.foundation.outputs.public_subnets_ids
  ecs_cluster_name         = data.terraform_remote_state.foundation.outputs.cluster_name 
  ecs_instance_profile_arn = data.terraform_remote_state.foundation.outputs.ec2_instance_profile_arn
  security-grp             = data.terraform_remote_state.foundation.outputs.ec2_sg-id

}

module "ecs_capacity_provider" {
  source                 = "../modules/ecs_capacity_provider"
  environment            = local.secret["environment"]
  auto_scaling_group_arn = module.auto_scaling.arn
  cluster_name           = data.terraform_remote_state.foundation.outputs.cluster_name
}


module "alb" {
  source             = "../modules/alb"
  alb_name           = "ecs-alb"
  alb_internal       = false
  load_balancer_type = "application"
  alb_security_group_ids = [
    data.terraform_remote_state.foundation.outputs.alb_sg-id
  ]
  alb_subnet_ids             = data.terraform_remote_state.foundation.outputs.public_subnets_ids
  enable_deletion_protection = false
  
  listeners={

    "443" = {
    port            = 443
    protocol        = "HTTPS"
    ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    certificate_arn = data.terraform_remote_state.foundation.outputs.certificate_arn
    action_type     = "fixed-response"
  },
    "15672" = {
      port     = 15672
      protocol = "HTTP"
      arn = data.terraform_remote_state.foundation.outputs.rabbitmq-tg-arn
    },
    "80" = {
      port     = 80
      protocol = "HTTP"
      action_type = "redirect"
    }
  }
  listener_rules = {
    "api_gateway" = {
      priority         = 1
      target_group_arn = data.terraform_remote_state.foundation.outputs.agw-tg-arn
      listener_key     = "443"
      header_condition = {
        name   = "X-Header-Secret"
        values = [local.secret["alb_custom_header_secret"]]
      }
    }
  }
}
