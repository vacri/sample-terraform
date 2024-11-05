output "opsnode_security_group" {
  description = "opsnode security group"
  value       = aws_security_group.opsnode.id
}

output "opsnode_network_id" {
  description = "opsnode instance network id"
  value       = aws_instance.opsnode.primary_network_interface_id
}

output "opsnode_instance_arn" {
  description = "ARN of the opsnode EC2 instance"
  value       = aws_instance.opsnode.arn
}

output "opsnode_iam_role_arn" {
  description = "ARN of the opsnode IAM Role"
  value       = aws_iam_role.opsnode.arn
}