#vpc_name = "vpc-${var.ou}-${var.env}"
vpc_cidr             = "172.30.16.0/21"
vpc_azs              = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
public_subnets       = ["172.30.20.0/24", "172.30.21.0/24", "172.30.22.0/24"]
private_subnets      = ["172.30.16.0/24", "172.30.17.0/24", "172.30.18.0/24"]
enable_nat_gateway   = false
use_nat_instance     = true
nat_instance_keypair = "nat-aaa-dev"