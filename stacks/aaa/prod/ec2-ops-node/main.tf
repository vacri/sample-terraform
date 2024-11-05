# TODO: stack-specific SNS topic

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

module "ec2_backups_node" {
  source = "../../../../modules/ec2-backups-node"

  ou             = var.ou
  env            = var.env
  cost_centre    = var.cost_centre
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region

  instance_type        = var.instance_type
  ec2_nametag          = var.ec2_nametag
  ec2_keypair          = var.ec2_keypair
  ami_filter_strings   = var.ami_filter_strings
  ami_owners           = var.ami_owners
  ec2_root_volume_size = var.ec2_root_volume_size

  s3_backup_write_perms = var.s3_backup_write_perms

  backups_secrets_access = var.backups_secrets_access
}

