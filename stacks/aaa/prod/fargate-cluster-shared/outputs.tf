output "vpc_id" {
  value = data.terraform_remote_state.vpc.outputs.vpc_id
}

output "cluster_arn" {
  value = module.fargate-cluster-shared.cluster_arn
}

output "alb_https_listener_arn" {
  value = module.fargate-cluster-shared.alb_https_listener_arn
}

output "alb_dns_name" {
  value = module.fargate-cluster-shared.alb_dns_name
}

output "alb_arn" {
  value = module.fargate-cluster-shared.alb_arn
}

output "alb_https_cert_arn" {
  value = var.https_listener_default_certificate_arn
}

output "cluster_subnets" {
  value = module.fargate-cluster-shared.cluster_subnets
}