output "logdb_security_group" {
  description = "logdb security group"
  value       = aws_security_group.logdb.id
}

output "logdb_network_id" {
  description = "logdb instance network id"
  value       = aws_instance.logdb.primary_network_interface_id
}

output "logdb_instance_arn" {
  description = "ARN of the logdb EC2 instance"
  value       = aws_instance.logdb.arn
}

output "logdb_iam_role_arn" {
  description = "ARN of the logdb IAM Role"
  value       = aws_iam_role.logdb.arn
}