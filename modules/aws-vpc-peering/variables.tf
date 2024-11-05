variable "owner" {
  type = map(string)
  default = {
    ou             = "unset"
    env            = "unset"
    aws_account_id = "unset"
    cost_centre    = "unset"
    cidr           = "unset"
  }
}

variable "remote" {
  type = map(string)
  default = {
    ou             = "unset"
    env            = "unset"
    aws_account_id = "unset"
    cost_centre    = "unset"
    cidr           = "unset"
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "peer_public_subnets" {
  type    = bool
  default = true
}