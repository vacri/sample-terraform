output "nat_security_group" {
  description = "NAT instance security group"
  value       = aws_security_group.nat_security_group
}

# output "nat_instance" {
#   description = "NAT EC2 instance"
#   value       = aws_instance.nat_instance
# }

output "nat_network_id" {
  description = "NAT instance network id"
  value       = aws_instance.nat_instance.primary_network_interface_id
}