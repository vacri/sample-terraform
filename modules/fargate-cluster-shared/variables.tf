variable "ou" {
  type = string
}

variable "env" {
  type = string
}

variable "capacity_provider" {
  type    = string
  default = "FARGATE"
}

variable "alb_idle_timeout" {
  type    = number
  default = 60 # aws default
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "https_listener_default_certificate_arn" {
  type     = string
  nullable = false
}
variable "https_listener_default_redirect_host" {
  type     = string
  nullable = false
}

variable "elb_ssl_policy" {
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies
  description = "AWS ELB SSL/TLS policy"
  type        = string
  # default is the AWS-recommended policy at time of writing
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}