provider "aws" {
  region = "ap-southeast-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform-deploy-superadmin"
  }
  default_tags {
    tags = {
      env                  = var.env
      terraform-stack-name = "${var.ou}-${var.env}-${basename(abspath(path.module))}"
      ou                   = var.ou
      cost-centre          = var.cost_centre
    }
  }
}

##
## VPC
##

resource "aws_eip" "nat" {
  # count changes if we turn off single_nat_gateway below
  count = var.single_nat_gateway ? 1 : length(var.private_subnets)
  vpc   = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.ou}-${var.env}"
  cidr = var.vpc_cidr

  azs = var.vpc_azs

  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.use_nat_instance ? false : true
  # be careful about turning nat gateway off - will create one nat per private subnet
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest#nat-gateway-scenarios
  single_nat_gateway = var.single_nat_gateway
  #reuse_nat_ips = true
  external_nat_ip_ids = aws_eip.nat.*.id

  enable_dns_hostnames = true
  enable_dns_support   = true

}


##
## NAT instance (optional)
##

module "nat_instance" {
  source = "../../../../modules/aws-nat-instance"

  count = var.use_nat_instance ? 1 : 0

  ou                  = var.ou
  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  subnet_id           = module.vpc.public_subnets[0]
  eip                 = aws_eip.nat[0].id
  keypair             = var.nat_instance_keypair
  nat_instance_config = var.nat_instance_config

}

resource "aws_route" "nat_instance_route" {
  count = var.use_nat_instance ? 1 : 0
  # can't combine count and for_each. route_table_ids is a list, which implies there can be many
  # we're going to assume that there's only one, and flip it on or off depending on whether we're using a nat instance (this route) or a nat gateway (the vpc module's route)
  #for_each = module.vpc.private_route_table_ids
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.nat_instance[0].nat_network_id
  depends_on             = [module.nat_instance, module.vpc]
}

##
## s3 endpoint
##

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "private_routes" {
  for_each        = toset(module.vpc.private_route_table_ids)
  route_table_id  = each.key
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "public_routes" {
  for_each        = toset(module.vpc.public_route_table_ids)
  route_table_id  = each.key
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

##
## RDS subnets
##

# the 'database subnet' option in the 'vpc' module requires its own cidr ranges, which we're not set up for

resource "aws_db_subnet_group" "rds_subnets" {
  name_prefix = "${var.ou}-${var.env}-"
  subnet_ids  = module.vpc.private_subnets
}

##
## vpc default security group ssh + outbound fix
##

resource "aws_security_group_rule" "ssh_from_anywhere" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpc.default_security_group_id
}

#if you get a conflict, try re-running the plan, and if still conflicting, comment out this stanza
resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpc.default_security_group_id
}