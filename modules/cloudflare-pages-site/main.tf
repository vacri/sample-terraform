# NOTE: the s3 public website will only serve on http (not https) if you
# give it an FQDN as the bucket name. You will need to manually add a Config Rule
# in Cloudflare to set ssl/tls for 'flexible' (http on backend). See commentary
# on the cloudflare records below for why this can't be done programmatically

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
    # github = {
    #   source  = "integrations/github"
    #   version = "~> 5.0"
    # }
  }
}

locals {
  # just the hostname, not an FQDN
  cdn_hostname = "${var.pages_site_config.name}-${var.assets_site_hostname_suffix}"
}

##
## Cloudflare Pages
##

resource "cloudflare_pages_project" "basic_project" {
  account_id        = var.cloudflare_account_id
  name              = var.pages_site_config.name
  production_branch = var.pages_source_config.production_branch

  #depends_on = [ github_repository.cloudflare_pages_repo ]

  build_config {
    build_command   = var.pages_build_config.build_command
    destination_dir = var.pages_build_config.destination_dir
  }
  deployment_configs {
    preview {
      environment_variables = var.pages_deployment_preview_configs.environment_variables
    }
    production {
      environment_variables = var.pages_deployment_production_configs.environment_variables
    }
  }
  source {
    type = "github"
    config {
      owner = var.pages_source_config.owner
      #repo_name = github_repository.cloudflare_pages_repo.name
      repo_name                  = var.pages_source_config.repo_name
      production_branch          = var.pages_source_config.production_branch
      preview_deployment_setting = "custom"
      preview_branch_includes    = var.pages_source_preview_config.preview_branch_includes
      preview_branch_excludes    = var.pages_source_preview_config.preview_branch_excludes
    }
  }
}

resource "cloudflare_pages_domain" "basic_project_domains" {
  # depends_on = [
  #   cloudflare_pages_project.basic_project
  # ]
  for_each = toset(var.domains)

  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.basic_project.name
  domain       = each.key
}

# ##
# ## Github Repo
# ##

# resource "github_repository" "cloudflare_pages_repo" {
#   name               = var.github_repo_name
#   visibility            = "private"
#   auto_init          = true
#   gitignore_template = var.gitignore_template


#   #  lifecycle {
#   #    prevent_destroy = true
#   #  }

# }

##
## S3 bucket + IAM admin user(s) (both optional)
##

module "s3_asset_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  create_bucket = var.s3_create_assets_bucket

  # TODO: change this so that there are no dots in the name
  #       s3 cannot cover a dotted name with its https cert
  #       so you have to MANUALLY make an override rule to request http on the backend
  #       (we default to requesting https on the backend, and cloudflare proxies do not
  #       follow redirects)
  # by default, NAMESPACE-cdn.aaa.tools
  bucket = "${var.pages_site_config.name}-${var.assets_site_hostname_suffix}.${var.assets_site_domain}"
  versioning = {
    status = true
  }

  # required for s3 'website'
  block_public_policy     = false
  block_public_acls       = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  attach_policy           = true
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Sid" : "PublicRead"
        "Principal" : "*"
        "Effect" : "Allow"
        "Action" : ["s3:GetObject"]
        "Resource" : [
          "${module.s3_asset_bucket.s3_bucket_arn}",
          "${module.s3_asset_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  website = {
    index_document = var.s3_website_config.index_document
    error_document = var.s3_website_config.error_document
  }

  # this is wide open CORS, but the data is public files anyway
  # revisit and/or make optional if we later need to tighten things up
  cors_rule = [
    {
      allowed_headers = [ "*" ]
      allowed_methods = [ "GET", "HEAD" ]
      allowed_origins = [ "*" ]
      max_age_seconds = 3600
      #expose_headers  = [ "*" ] # can't do wildcards here
    }
  ]
}

resource "aws_iam_user" "s3_rw" {
  for_each = toset(var.s3_iam_users)
  name     = "${each.key}-${var.pages_site_config.name}-${var.assets_site_hostname_suffix}-rw"

  # allows destroy when there's non-terraform-managed access keys
  force_destroy = true
}

resource "aws_iam_user_policy" "s3_writer" {
  for_each = aws_iam_user.s3_rw

  user = each.value["name"]

  # policy should give read/write on all object actions, but not bucket admin actions
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Sid" : "S3ReadWriteObjects"
        "Effect" : "Allow"
        "Action" : [
          "s3:*Object",
          "s3:*Object*",
        ]
        "Resource" : [
          "${module.s3_asset_bucket.s3_bucket_arn}",
          "${module.s3_asset_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        "Sid" : "S3ListBucket"
        "Effect" : "Allow"
        "Action" : [
          "s3:ListBucket",
          "s3:ListBucket*"
        ]
        "Resource" : [
          "${module.s3_asset_bucket.s3_bucket_arn}"
        ]
      }
    ]
  })
}

##
## Cloudflare cdn/proxy/dns record (image resize is automatic, if enabled on the zone in the web console)
##

data "cloudflare_zones" "domain" {
  filter {
    name = var.assets_site_domain
  }
}

resource "cloudflare_record" "assets_cdn" {
  count = var.s3_create_assets_bucket ? 1 : 0

  zone_id = data.cloudflare_zones.domain.zones[0].id
  #name    = "${var.pages_site_config.name}-${var.assets_site_hostname_suffix}"
  name    = local.cdn_hostname
  value   = module.s3_asset_bucket.s3_bucket_website_domain
  type    = "CNAME"
  proxied = true
}

## this resource is meant to force requests on the given domain to go
## to http/80, as s3 websites only work for custom domains if the bucket
## matches the FQDN and is on port 80. HTTPS certs are not supported for
## FQDN-style buckets, as the 'dots' in the name means the s3 wildcard
## ssl can't work
##
## ... HOWEVER ...
##
## This does not work as either 'origin rules' or 'config rules'
## Cloudflare's API does not do separate individual rules, apparently.
## So you can configure the first stack with these items, but the second stack will
## fail with an "omg! you're going to overwrite the other rule!" error.
## So... put the rule in manually. Damn.
##
## (the issue is that if the Cloudflare zone is set to 'flexible' ssl, it uses http
## on the backend, which we don't want by default. but s3 doesn't work with FQDN
## domains on the backend for https, so if we want to switch to 'full' ssl (https on
## the backend), we need to override this style of s3 bucket back to http)
## (also: changing 'kind' from 'zone' to 'managed' or 'custom' gets rejected)
## https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/ruleset
# resource "cloudflare_ruleset" "s3_website_force_http_on_backend" {
#   count = var.s3_create_assets_bucket ? 1 : 0
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   # neither this name nor description show up in the web console!
#   name = "s3 http hax"
#   description = "s3 http hax"
#   kind = "zone"
#   phase = "http_request_origin"
#   rules {
#     expression = "(http.host eq \"${local.cdn_hostname}.${var.assets_site_domain}\")"
#     action = "route"
#     enabled = true
#     action_parameters {
#       origin {
#         port = 80
#       }
#     }
#   }
# }
