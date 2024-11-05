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

output "ecr_repo_name" {
  value = local.ecr_repo_name
}

output "service_role_arn" {
  value = module.fargate_web_app.ecs_service_role_arn
}

output "task_role_arn" {
  value = module.fargate_web_app.ecs_task_role_arn
}

output "task_execution_role" {
  value = module.fargate_web_app.ecs_task_execution_role_arn
}

output "github_actions_role" {
  value = module.fargate_web_app.github_actions_role_arn
}

output "task_definition" {
  value = module.fargate_web_app.task_definition_arn
}

output "ecs_cluster_arn" {
  value = module.fargate_web_app.ecs_cluster_arn
}

output "security_groups" {
  value = module.fargate_web_app.security_groups
}

output "alb_target_group" {
  value = module.fargate_web_app.alb_target_group
}

output "container_name" {
  value = module.fargate_web_app.container_name
}

output "container_port" {
  value = module.fargate_web_app.container_port
}

output "alb_https_listener_priority" {
  value = module.fargate_web_app.alb_https_listener_priority
}

output "container_count_min" {
  value = module.fargate_web_app.container_count_min
}

output "container_count_max" {
  value = module.fargate_web_app.container_count_max
}

output "ecs_task_env_file" {
  value = module.fargate_web_app.ecs_task_env_file
}

output "s3_assets_bucket_arn" {
  value = module.fargate_web_app.s3_assets_bucket_arn
}

output "s3_assets_bucket_name" {
  value = module.fargate_web_app.s3_assets_bucket_name
}
output "ecr_repo_url" {
  value = module.fargate_web_app.ecr_repo_url
}

output "ecs_service_name" {
  value = module.fargate_web_app.ecs_service_name
}