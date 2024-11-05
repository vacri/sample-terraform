# depends on associated module called 'aws-vpc'

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = [aws.owner, aws.remote]
    }
  }
}

# central/hub vpc
data "terraform_remote_state" "owner" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.owner.ou}/${var.owner.env}/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "remote" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.remote.ou}/${var.remote.env}/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_vpc_peering_connection" "peer_connection" {
  provider      = aws.owner
  vpc_id        = data.terraform_remote_state.owner.outputs.vpc_id
  peer_vpc_id   = data.terraform_remote_state.remote.outputs.vpc_id
  peer_owner_id = var.remote.account_id

  tags = {
    Name = "${var.remote.ou}-${var.remote.env}"
  }
}

resource "aws_vpc_peering_connection_accepter" "remote_accepter" {
  provider                  = aws.remote
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_connection.id
  auto_accept               = true

  tags = {
    Name = "sharedservices"
  }
}

resource "aws_route" "owner_private_routes" {
  provider                  = aws.owner
  for_each                  = toset(data.terraform_remote_state.owner.outputs.private_route_table_ids)
  route_table_id            = each.key
  destination_cidr_block    = data.terraform_remote_state.remote.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_connection.id
}

resource "aws_route" "remote_private_routes" {
  provider                  = aws.remote
  for_each                  = toset(data.terraform_remote_state.remote.outputs.private_route_table_ids)
  route_table_id            = each.key
  destination_cidr_block    = data.terraform_remote_state.owner.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_connection.id
}

resource "aws_route" "owner_public_routes" {
  #count = var.peer_public_subnets ? 1 : 0  # can't do count and for_each in same stanza
  provider                  = aws.owner
  for_each                  = toset(data.terraform_remote_state.owner.outputs.public_route_table_ids)
  route_table_id            = each.key
  destination_cidr_block    = data.terraform_remote_state.remote.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_connection.id
}

resource "aws_route" "remote_public_routes" {
  #count = var.peer_public_subnets ? 1 : 0
  provider                  = aws.remote
  for_each                  = toset(data.terraform_remote_state.remote.outputs.public_route_table_ids)
  route_table_id            = each.key
  destination_cidr_block    = data.terraform_remote_state.owner.outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer_connection.id
}