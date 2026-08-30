output "vpc_id" {
  value = module.my_vpc.vpc_id
}

output "ecs_task_execution_role_arn" {
  value = module.ecs_task_execution_role.ecs_task_execution_role_arn
}

output "ec2_instance_profile_arn" {
  value = module.ec2_execution_role.ec2_instance_profile_arn
}

output "cluster_id" {
  value = module.my_cluster.cluster_id
}

output "cluster_name" {
  value = module.my_cluster.cluster_name
}

output "ec2_sg-id" {
  value = module.ec2_sg.sg-id
}

output "agw-sg-id" {
  value = module.api_gateway_sg.sg-id
}

output "public_subnets_ids" {
  value = module.my_vpc.public_subnets_ids
}

output "log_group_name" {
  value = module.cloud_watch_log_group.log_group_name
}

output "service_discovery_namespace_arn" {
  value = module.service_discovery_namespace.service_discovery_namespace_arn
}

output "agw-tg-arn" {
  value = module.target_groups["api-gateway"].arn
}

