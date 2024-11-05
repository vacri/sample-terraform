##
## S3 bucket (optional)
##
data "aws_iam_policy_document" "s3_public_website_policy" {
  statement {
    sid    = "S3WebsitePublicAccess"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]

    resources = ["arn:aws:s3:::${local.s3_assets_bucket}/*"]
  }
}

module "s3_assets_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  count  = var.create_s3_assets_bucket ? 1 : 0

  bucket = local.s3_assets_bucket

  website = var.s3_enable_assets_website ? var.s3_website_config : {}
  # turning on an s3 website means disabling all/most of the access blocks AND adding an IAM policy
  block_public_acls       = !var.s3_enable_assets_website
  block_public_policy     = !var.s3_enable_assets_website
  restrict_public_buckets = !var.s3_enable_assets_website
  attach_policy           = var.s3_enable_assets_website
  policy                  = data.aws_iam_policy_document.s3_public_website_policy.json

  lifecycle_rule = [
    {
      # this rule will eventually expire objects that have been overwritten
      id     = "TransitionOldVersions"
      status = "Enabled"
      noncurrent_version_transition = {
        noncurrent_days = var.s3_noncurrent_transition_days
        storage_class   = "GLACIER"
      }
      noncurrent_version_expiration = {
        noncurrent_days = var.s3_noncurrent_expiration_days
      }
    },
    {
      # this rule can ensure that objects are in a particular storage class (eg: STANDARD_IA)
      id     = "TransitionCurrentVersions"
      status = var.s3_enable_current_version_transition ? "Enabled" : "Disabled"
      transition = {
        days          = var.s3_current_transition_days
        storage_class = var.s3_current_transition_storage_class
      }
    }
  ]

  tags = {
    backup = var.s3_backup_tag
  }

  versioning = {
    enabled = true
  }
}

data "cloudflare_zones" "aaa.tools_domain" {
  filter {
    name = var.cloudflare_zone
  }
}

resource "cloudflare_record" "s3_assets_website" {
  count = var.s3_enable_assets_website ? 1 : 0

  zone_id = data.cloudflare_zones.aaa.tools_domain.zones[0].id
  name    = local.s3_cdn_website_name_prefix
  value   = module.s3_assets_bucket[0].s3_bucket_website_endpoint
  type    = "CNAME"
  proxied = true
}


#### This host header rewrite does not work as expected, so is disabled:
#### * the correct rule type should be an Origin Rule, not a Page Rule
####    * the method below works, but Origin Rule is a better fit
#### * there ALSO needs to be a 'force http' Configuration Rule
####    * if you're default to https on the backend, that is
####    * s3 does not support https for custom domains, so http it is
#### * none of these rulesets can be made piecemeal
####    * the entire ruleset block must be assigned at once
####    * you can do the first app-specific rule via Terraform...
####      ... but the second app-specific rule you add will conflict
#### As a result of the third point, these rules need to be *manually*
#### created in Cloudflare, andd can't be handled easily in Terraform.
# # this rewrites the host header on the request to the s3 bucket,
# # otherwise the s3 bucket MUST match the FQDN of the cdn domain.
# # this rewrite decouples the s3 bucket name from the domain name
# resource "cloudflare_page_rule" "s3_website_rewrite_host_header" {
#   count = var.s3_enable_assets_website ? 1 : 0
#   zone_id = data.cloudflare_zones.aaa.tools_domain.zones[0].id
#   target = "${local.s3_cdn_website_name_prefix}.${var.cloudflare_zone}/*"
#   priority = 1

#   actions {
#     host_header_override = "${module.s3_assets_bucket[0].s3_bucket_website_endpoint}"
#   }
# }