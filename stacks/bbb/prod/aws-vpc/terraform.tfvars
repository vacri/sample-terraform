#vpc_name = "vpc-${var.ou}-${var.env}"
vpc_cidr             = "172.30.24.0/21"
vpc_azs              = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
public_subnets       = ["172.30.28.0/24", "172.30.29.0/24", "172.30.30.0/24"]
private_subnets      = ["172.30.24.0/24", "172.30.25.0/24", "172.30.26.0/24"]
enable_nat_gateway   = false
use_nat_instance     = true
nat_instance_keypair = "nat-bbb-prod"
