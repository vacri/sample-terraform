output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "public_route_table_ids" {
  description = "List of public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "cost_centre" {
  description = "cost centre"
  value       = var.cost_centre
}

output "vpc_cidr" {
  description = "vpc_cidr"
  value       = module.vpc.vpc_cidr_block
}


output "db_subnet_group_name" {
  description = "db subnet group name"
  value       = aws_db_subnet_group.rds_subnets.name
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
output "private_subnets_cidr_blocks" {
  description = "private subnet cidr blocks"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
output "public_subnets_cidr_blocks" {
  value = module.vpc.public_subnets_cidr_blocks
}