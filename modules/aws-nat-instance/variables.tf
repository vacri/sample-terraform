variable "ou" {
  type    = string
  default = "unset"
}

variable "env" {
  type    = string
  default = "unset"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type = string
}

variable "eip" {
  type = string
}

# kept together in a map as ami + arch are related
variable "nat_instance_config" {
  type = map(string)
  default = {
    ami_id        = "ami-0864086ece51b0aea"
    instance_type = "t4g.nano"
    arch          = "arm64" # used to retrieve SSM agent module (or make the userdata script detect architecture)
  }
}
# # AMI must be arm or x86 to match the instance type!
# variable "ami_id" {
#   type    = string
#   default = "ami-0864086ece51b0aea"
# }

variable "subnet_id" {
  type     = string
  nullable = false
}

# variable "instance_type" {
#   type    = string
#   default = "t4g.nano"
# }

variable "keypair" {
  type    = string
  default = ""
}

