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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "aaaops_vpc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "aaaops/prod/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  name = "${var.ou}-${var.env}-${var.engine}-shared"
}

resource "aws_security_group" "db_sg" {
  name   = "${local.name}-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port = var.port
    to_port   = var.port
    protocol  = "tcp"
    #aaaops_vpc = vpn endpoint, ops servers (backups, logserver, etc)
    cidr_blocks = concat(
      data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks,
      data.terraform_remote_state.aaaops_vpc.outputs.private_subnets_cidr_blocks,
      # public subnets are needed as we're using a jumphost instead of AWS site-to-site VPN
      data.terraform_remote_state.aaaops_vpc.outputs.public_subnets_cidr_blocks
    )
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "db" {
  # 'identifier' is name of the host, 'name' is name of the initial db (we don't add that)
  identifier                 = local.name
  engine                     = var.engine
  engine_version             = var.engine_version
  auto_minor_version_upgrade = true
  instance_class             = var.instance_class
  apply_immediately          = var.apply_immediately

  parameter_group_name       = aws_db_parameter_group.aaa_mysql_params.name

  # to destroy, turn off deletion protection, then 'apply' that setting, then 'destroy'
  # to avoid a final snapshot, also need to 'apply' skip=true before 'destroy'
  deletion_protection = true
  #skip_final_snapshot = false
  #final_snapshot_identifier = "${local.name}-final"

  # it's not clear how these two interact, but generally we want stuff in AZ 'a'
  multi_az          = var.multi_az
  availability_zone = var.availability_zone

  username                    = "root"
  manage_master_user_password = true # creates a rotating password in Secrets Manager

  # use of io1 ($$$$$), gp3, or magnetic is not expected
  storage_type          = "gp2"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  port                   = var.port
  db_subnet_group_name   = data.terraform_remote_state.vpc.outputs.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  #parameter_group_name = var.paramater_group_name
  #option_group_name = var.option_group_name

  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period
  maintenance_window      = var.maintenance_window

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = "arn:aws:iam::${var.aws_account_id}:role/rds-monitoring-role"

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? 7 : null # free tier

  tags = var.extra_tags

  lifecycle {
    ignore_changes = [
      engine_version
    ]
  }

}

resource "aws_db_parameter_group" "aaa_mysql_params" {

  name = "${local.name}-params"
  family = "mysql8.0"

  ## recommended by drupal, couldn't find any solid args against it
  ## apparently the default for psql + oracle
  parameter {
    name = "transaction_isolation"
    value = "READ-COMMITTED"
  }

}


## don't use this module. It doesn't do much that the 'resource' above doesn't, and is missing password management functionality
# module "db" {
#   source     = "terraform-aws-modules/rds/aws"
