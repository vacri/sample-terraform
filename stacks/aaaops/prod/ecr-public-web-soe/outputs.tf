output "github_actions_iam_role_arn" {
  value = module.ecr_public_repo.github_actions_iam_role_arn
}
output "github_actions_iam_role_name" {
  value = module.ecr_public_repo.github_actions_iam_role_name
}

output "ecr_repo_id" {
  value = module.ecr_public_repo.ecr_repo_id
}
output "ecr_repo_arn" {
  value = module.ecr_public_repo.ecr_repo_arn
}
output "ecr_repo_uri" {
  value = module.ecr_public_repo.ecr_repo_uri
}
output "ecr_repo_registry_id" {
  value = module.ecr_public_repo.ecr_repo_registry_id
}