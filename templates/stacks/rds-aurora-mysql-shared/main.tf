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

module "aurora_mysql_serverless_v2" {
  source         = "terraform-aws-modules/rds-aurora/aws"
  name           = "${var.ou}-${var.env}-${var.aurora_config.name_suffix}"
  engine         = var.aurora_config.engine
  engine_version = var.aurora_config.version
  engine_mode    = "provisioned"

  master_username             = var.aurora_config.master_username
  manage_master_user_password = true

  vpc_id               = data.terraform_remote_state.vpc.outputs.vpc_id
  db_subnet_group_name = data.terraform_remote_state.vpc.outputs.db_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = data.terraform_remote_state.vpc.outputs.private_subnets_cidr_blocks
    }
  }

  apply_immediately = true
  #final_snapshot_identifier = "final"

  # # shenanigans are required to destroy an aurora cluster. see: 
  # # https://stackoverflow.com/questions/50930470/terraform-error-rds-cluster-finalsnapshotidentifier-is-required-when-a-final-s
  # # these fields need to be uncommented/toggled in and the final_snapshot_identifier field basically doesn't work
  # # then you need to 'apply' the settings before attempting the 'destroy'
  # skip_final_snapshot = true
  # preferred_backup_window = null
  # backup_retention_period = 0

  serverlessv2_scaling_configuration = {
    min_capacity = var.aurora_config.min_capacity
    max_capacity = var.aurora_config.max_capacity
  }

  instance_class = "db.serverless"
  # don't remove the last instance or you will 'empty' the cluster
  instances = {
    one = {}
  }


}
