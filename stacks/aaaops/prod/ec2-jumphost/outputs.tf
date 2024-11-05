output "jumphost_security_group" {
  description = "Jumphost security group"
  value       = module.jumphost.jumphost_security_group
}

output "jumphost_network_id" {
  description = "Jumphost instance network id"
  value       = module.jumphost.jumphost_network_id
}

output "jumphost_ip" {
  description = "Public IP of the jumphost (Elastic IP)"
  value       = module.jumphost.jumphost_ip
}

output "jumphost_instance_arn" {
  description = "ARN of the jumphost EC2 instance"
  value       = module.jumphost.jumphost_instance_arn
}

output "jumphost_iam_role_arn" {
  description = "ARN of the jumphost IAM Role"
  value       = module.jumphost.jumphost_iam_role_arn
}