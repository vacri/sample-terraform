output "jumphost_security_group" {
  description = "Jumphost security group"
  value       = aws_security_group.jumphost.id
}

output "jumphost_network_id" {
  description = "Jumphost instance network id"
  value       = aws_instance.jumphost.primary_network_interface_id
}

output "jumphost_ip" {
  description = "Public IP of the jumphost (Elastic IP)"
  value       = aws_eip.jumphost.id
}

output "jumphost_instance_arn" {
  description = "ARN of the jumphost EC2 instance"
  value       = aws_instance.jumphost.arn
}

output "jumphost_iam_role_arn" {
  description = "ARN of the jumphost IAM Role"
  value       = aws_iam_role.jumphost.arn
}