terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

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

module "cloudflare-pages-site" {
  source                              = "../../../../modules/cloudflare-pages-site"
  cloudflare_account_id               = var.cloudflare_account_id
  pages_site_config                   = var.pages_site_config
  pages_build_config                  = var.pages_build_config
  pages_source_config                 = var.pages_source_config
  domains                             = var.domains
  pages_deployment_preview_configs    = var.pages_deployment_preview_configs
  pages_deployment_production_configs = var.pages_deployment_production_configs

  s3_create_assets_bucket = var.s3_create_assets_bucket

  s3_iam_users = var.s3_iam_users
}
