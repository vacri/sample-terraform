output "github_actions_iam_role_arn" {
  value = aws_iam_role.github_actions_cicd[0].arn
}
output "github_actions_iam_role_name" {
  value = aws_iam_role.github_actions_cicd[0].name
}

output "ecr_repo_id" {
  value = aws_ecrpublic_repository.this.id
}
output "ecr_repo_arn" {
  value = aws_ecrpublic_repository.this.arn
}
output "ecr_repo_uri" {
  value = aws_ecrpublic_repository.this.repository_uri
}
output "ecr_repo_registry_id" {
  value = aws_ecrpublic_repository.this.registry_id
}