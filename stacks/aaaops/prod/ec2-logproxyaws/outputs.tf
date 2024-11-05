output "logproxy_security_group" {
  description = "logproxy security group"
  value       = aws_security_group.logproxy.id
}

output "logproxy_network_id" {
  description = "logproxy instance network id"
  value       = aws_instance.logproxy.primary_network_interface_id
}

output "logproxy_instance_arn" {
  description = "ARN of the logproxy EC2 instance"
  value       = aws_instance.logproxy.arn
}

output "logproxy_iam_role_arn" {
  description = "ARN of the logproxy IAM Role"
  value       = aws_iam_role.logproxy.arn
}