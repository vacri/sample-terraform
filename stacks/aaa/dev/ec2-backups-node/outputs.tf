output "security_group" {
  description = "backupsnode security group"
  value       = module.ec2_backups_node.security_group
}

output "network_id" {
  description = "backupsnode instance network id"
  value       = module.ec2_backups_node.network_id
}

output "instance_arn" {
  description = "ARN of the backupsnode EC2 instance"
  value       = module.ec2_backups_node.instance_arn
}

output "iam_role_arn" {
  description = "ARN of the backupsnode IAM Role"
  value       = module.ec2_backups_node.iam_role_arn
}