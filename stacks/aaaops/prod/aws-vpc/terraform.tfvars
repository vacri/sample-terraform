#vpc_name = "vpc-${var.ou}-${var.env}"
vpc_cidr             = "172.30.0.0/21"
vpc_azs              = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
public_subnets       = ["172.30.4.0/24", "172.30.5.0/24", "172.30.6.0/24"]
private_subnets      = ["172.30.0.0/24", "172.30.1.0/24", "172.30.2.0/24"]
enable_nat_gateway   = false
use_nat_instance     = true
nat_instance_keypair = "nat-shared-services"
