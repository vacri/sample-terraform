variable "https_listener_default_certificate_arn" {
  type     = string
  nullable = false
}

variable "https_listener_default_redirect_host" {
  type    = string
  default = "www.aaa.tools"
}

variable "elb_ssl_policy" {
  # https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies
  description = "AWS ELB SSL/TLS policy"
  type        = string
  # default is the AWS-recommended policy at time of writing
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}