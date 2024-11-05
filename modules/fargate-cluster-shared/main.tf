terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  namespace = "${var.ou}-${var.env}-ecs-shared"
}

##
## Fargate cluster
##

resource "aws_ecs_cluster" "fargate" {
  name = local.namespace
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name       = aws_ecs_cluster.fargate.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

##
## Shared ELB
##

# aws_lb has a few options https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_alb" "fargate_alb" {
  name               = local.namespace
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb.id]

  idle_timeout = var.alb_idle_timeout

  access_logs {
    bucket  = "${var.ou}-${var.env}-logs"
    prefix  = "elb/${local.namespace}"
    enabled = true
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.fargate_alb.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.fargate_alb.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.elb_ssl_policy
  certificate_arn   = var.https_listener_default_certificate_arn
  default_action {
    type = "redirect"

    redirect {
      host        = var.https_listener_default_redirect_host
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.ou}-${var.env}-shared-sg"
  description = "web ports for fargate cluster ELB"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.alb.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.alb.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}