# 'owner' = the peering source account, the one this stack is run in. It should be the hub account
# 'remote' = the peering remote account. There should be a map of several client accounts

##
## Providers
##

provider "aws" {
  alias  = "aaaops"
  region = var.aws_region
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

# accounts = {
#   aaadev = {
#     account_id  = "123456789012"
#     ou          = "aaa"
#     env         = "dev"
#   },
#     aaaprod = {
#     account_id  = "2345678901234"
#     ou          = "aaa"
#     env         = "prod"
#   },
#     bbbdev = {
#     account_id  = "997358959085"
#     ou          = "bbb"
#     env         = "dev"
#   },
#     bbbprod = {
#     account_id  = "517415646650"
#     ou          = "bbb"
#     env         = "prod"
#   }
# }

# Terraform cannot pass dynamic providers, so we have to separately list all providers,
# as well as separately list module calls for those providers :/
# note that the tags on this resource should point to THIS stack, not the remote account,
# hence why they're using vars for this particular stack
provider "aws" {
  alias  = "aaadev"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/terraform-deploy-superadmin"
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
provider "aws" {
  alias  = "aaaprod"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::2345678901234:role/terraform-deploy-superadmin"
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
provider "aws" {
  alias  = "bbbdev"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::997358959085:role/terraform-deploy-superadmin"
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
provider "aws" {
  alias  = "bbbprod"
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::517415646650:role/terraform-deploy-superadmin"
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


module "vpc_peering_aaadev" {
  source = "../../../../modules/aws-vpc-peering"
  providers = {
    aws.owner  = aws.aaaops
    aws.remote = aws.aaadev
  }

  owner = {
    ou             = var.ou
    env            = var.env
    aws_account_id = var.aws_account_id
  }

  remote = {
    ou         = "aaa"
    env        = "dev"
    account_id = "123456789012"
  }
}

module "vpc_peering_aaaprod" {
  source = "../../../../modules/aws-vpc-peering"
  providers = {
    aws.owner  = aws.aaaops
    aws.remote = aws.aaaprod
  }

  owner = {
    ou             = var.ou
    env            = var.env
    aws_account_id = var.aws_account_id
  }

  remote = {
    ou         = "aaa"
    env        = "prod"
    account_id = "2345678901234"
  }
}

module "vpc_peering_bbbdev" {
  source = "../../../../modules/aws-vpc-peering"
  providers = {
    aws.owner  = aws.aaaops
    aws.remote = aws.bbbdev
  }

  owner = {
    ou             = var.ou
    env            = var.env
    aws_account_id = var.aws_account_id
  }

  remote = {
    ou         = "bbb"
    env        = "dev"
    account_id = "997358959085"
  }
}

module "vpc_peering_bbbprod" {
  source = "../../../../modules/aws-vpc-peering"
  providers = {
    aws.owner  = aws.aaaops
    aws.remote = aws.bbbprod
  }

  owner = {
    ou             = var.ou
    env            = var.env
    aws_account_id = var.aws_account_id
  }

  remote = {
    ou         = "bbb"
    env        = "prod"
    account_id = "517415646650"
  }
}