#vpc_name = "vpc-${var.ou}-${var.env}"
vpc_cidr             = "172.30.32.0/21"
vpc_azs              = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
public_subnets       = ["172.30.36.0/24", "172.30.37.0/24", "172.30.38.0/24"]
private_subnets      = ["172.30.32.0/24", "172.30.33.0/24", "172.30.34.0/24"]
enable_nat_gateway   = false
use_nat_instance     = true
nat_instance_keypair = "nat-bbb-dev"
