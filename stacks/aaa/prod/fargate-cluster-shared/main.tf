# This module provides an empty cluster with a loadbalancer. 
# Client modules will install services/tasks into this cluster and attach to the loadbalancer

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

data "aws_availability_zones" "available" {
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/aws-vpc/terraform.tfstate"
    region = var.aws_region
  }
}



module "fargate-cluster-shared" {
  source = "../../../../modules/fargate-cluster-shared"
  ou     = var.ou
  env    = var.env

  vpc_id                                 = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets                         = data.terraform_remote_state.vpc.outputs.public_subnets
  private_subnets                        = data.terraform_remote_state.vpc.outputs.private_subnets
  https_listener_default_certificate_arn = var.https_listener_default_certificate_arn
  https_listener_default_redirect_host   = var.https_listener_default_redirect_host
  elb_ssl_policy                         = var.elb_ssl_policy

}