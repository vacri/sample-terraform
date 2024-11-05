# variable "vpc_name" {
#     type = string
#     default = ""
# }

variable "vpc_cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "vpc_azs" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["172.31.0.0/24", "172.31.1.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["172.31.10.0/24", "172.31.11.0/24"]

}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "use_nat_instance" {
  type    = bool
  default = false
}

variable "nat_instance_keypair" {
  type    = string
  default = ""
}

variable "nat_instance_config" {
  type = map(string)
  default = {
    ami_id        = "ami-0864086ece51b0aea"
    instance_type = "t4g.nano"
    arch          = "arm64" # used to retrieve SSM agent module
  }
}