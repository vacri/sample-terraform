# used for CNAME in dns
output "alb_dns_name" {
  value = data.terraform_remote_state.fargate_cluster.outputs.alb_dns_name
}

output "alb_arn" {
  value = data.terraform_remote_state.fargate_cluster.outputs.alb_arn
}

output "host_headers" {
  value = var.host_headers
}

output "service_role_arn" {
  value = module.fargate_web_app_with_efs.ecs_service_role_arn
}

output "task_role_arn" {
  value = module.fargate_web_app_with_efs.ecs_task_role_arn
}

output "task_execution_role" {
  value = module.fargate_web_app_with_efs.ecs_task_execution_role_arn
}

output "github_actions_role" {
  value = module.fargate_web_app_with_efs.github_actions_role_arn
}

output "task_definition" {
  value = module.fargate_web_app_with_efs.task_definition_arn
}

output "ecs_cluster_arn" {
  value = module.fargate_web_app_with_efs.ecs_cluster_arn
}

output "security_groups" {
  value = module.fargate_web_app_with_efs.security_groups
}

output "alb_target_group" {
  value = module.fargate_web_app_with_efs.alb_target_group
}

output "container_name" {
  value = module.fargate_web_app_with_efs.container_name
}

output "container_port" {
  value = module.fargate_web_app_with_efs.container_port
}

output "alb_https_listener_priority" {
  value = module.fargate_web_app_with_efs.alb_https_listener_priority
}

output "container_count_min" {
  value = module.fargate_web_app_with_efs.container_count_min
}

output "container_count_max" {
  value = module.fargate_web_app_with_efs.container_count_max
}

output "ecs_task_env_file" {
  value = module.fargate_web_app_with_efs.ecs_task_env_file
}

output "s3_assets_bucket_arn" {
  value = module.fargate_web_app_with_efs.s3_assets_bucket_arn
}

output "s3_assets_bucket_name" {
  value = module.fargate_web_app_with_efs.s3_assets_bucket_name
}
output "ecr_repo_url" {
  value = module.fargate_web_app_with_efs.ecr_repo_url
}

output "ecs_service_name" {
  value = module.fargate_web_app_with_efs.ecs_service_name
}

output "local_ecr_repo_arn" {
  value = var.create_ecr_repo ? module.fargate_web_app_with_efs.ecr_repo_arn : null
}