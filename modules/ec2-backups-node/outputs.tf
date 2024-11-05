output "security_group" {
  description = "backupsnode security group"
  value       = aws_security_group.ec2_backups_nodes.id
}

output "network_id" {
  description = "backupsnode instance network id"
  value       = aws_instance.backupsnode.primary_network_interface_id
}

output "instance_arn" {
  description = "ARN of the backupsnode EC2 instance"
  value       = aws_instance.backupsnode.arn
}

output "iam_role_arn" {
  description = "ARN of the backupsnode IAM Role"
  value       = aws_iam_role.backups_node.arn
}