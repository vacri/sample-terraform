output "cluster_arn" {
  value = aws_ecs_cluster.fargate.arn
}

output "alb_http_listener_arn" {
  value = aws_alb_listener.http_listener.arn
}

output "alb_https_listener_arn" {
  value = aws_alb_listener.https_listener.arn
}

output "alb_dns_name" {
  value = aws_alb.fargate_alb.dns_name
}

output "alb_arn" {
  value = aws_alb.fargate_alb.arn
}

output "cluster_subnets" {
  value = var.private_subnets
}