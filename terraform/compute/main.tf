module "auto_scaling" {
  source                   = "../modules/auto-scalling"
  environment              = local.secret["environment"]
  instance_type            = "t3.micro"
  desired_capacity         = 6
  max_size                 = 9
  min_size                 = 1
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