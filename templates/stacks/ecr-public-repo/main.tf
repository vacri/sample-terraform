provider "aws" {
  region = "us-east-1"
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

module "ecr_public_repo" {
  source = "../../../../modules/ecr-public-repo"

  ecr_repo_name  = var.ecr_repo_name
  aws_account_id = var.aws_account_id
  github_repo    = var.github_repo
}

