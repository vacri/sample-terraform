# variable "accounts" {
#   #type = map(map)
# }

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "owner_cidr" {
  type = string
}

# variable "owner" {
#   type = map(string)
#   default = {
#     ou             = "unset"
#     env            = "unset"
#     aws_account_id = "unset"
#     cost_centre    = "unset"
#     cidr           = "unset"
#   }
# }

# variable "remote" {
#   type = map(string)
#   default = {
#     ou             = "unset"
#     env            = "unset"
#     aws_account_id = "unset"
#     cost_centre    = "unset"
#     cidr           = "unset"
#   }
# }

variable "peer_public_subnets" {
  type    = bool
  default = true
}