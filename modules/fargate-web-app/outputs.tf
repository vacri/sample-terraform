output "ecs_service_role_arn" {
  value = aws_iam_role.ecs_service_role.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "github_actions_role_arn" {
  value = var.github_repo != "" ? aws_iam_role.github_actions_cicd[0].arn : null
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.app.arn
}

output "ecs_cluster_arn" {
  value = var.ecs_cluster_arn
}

output "security_groups" {
  value = aws_security_group.ecs_service.id
}

output "alb_target_group" {
  value = aws_alb_target_group.app.arn
}

output "container_name" {
  value = "${var.app}-${var.env}-app"
}

output "container_image" {
  value = local.container_image
}

output "container_label" {
  value = local.container_label
}

output "container_port" {
  value = local.container_port
}

output "alb_https_listener_priority" {
  value = var.alb_https_listener_priority
}

output "container_count_min" {
  value = var.container_count_min
}

output "container_count_max" {
  value = var.container_count_max
}

output "ecs_task_env_file" {
  value = var.s3_task_env_key
}

output "s3_assets_bucket_arn" {
  value = try(length(module.s3_assets_bucket[0]) > 0, false) ? module.s3_assets_bucket[0].s3_bucket_arn : null
}

output "s3_assets_bucket_name" {
  value = try(length(module.s3_assets_bucket[0]) > 0, false) ? module.s3_assets_bucket[0].s3_bucket_id : null
}

## this output is just the parent domain of the bucket's full FQDN
# output "s3_bucket_website_domain" {
#   value = var.create_s3_assets_bucket ? module.s3_assets_bucket[0].s3_bucket_website_domain : null
# }

output "s3_bucket_website_endpoint" {
  value = var.create_s3_assets_bucket ? module.s3_assets_bucket[0].s3_bucket_website_endpoint : null
}

output "ecr_repo_url" {
  value = var.create_ecr_repo ? aws_ecr_repository.app[0].repository_url : null
}

output "ecr_repo_arn" {
  value = var.create_ecr_repo ? aws_ecr_repository.app[0].arn : null
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}
output "zzbloodyhell" {
  value = module.fargate_efs_submodule
}