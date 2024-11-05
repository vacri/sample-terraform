# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
# }

# all buckets require public block (module default) + versioning turned on
# backups = place to put backup data in same AWS account
# configs = place to put ECS task.env files and other s3-based config files
# logs = place to put s3-based logging
# packages = place to put deployment packages (tars, zips, etc)

locals {
  buckets = {
    backups = {
      noncurrent_transition = 14
      noncurrent_expire     = 180
      elb_logs              = false
      enable_backup         = false
    },
    configs = {
      noncurrent_transition = 14
      noncurrent_expire     = 180
      elb_logs              = false
      enable_backup         = true
    },
    logs = {
      noncurrent_transition = 14
      noncurrent_expire     = 180
      elb_logs              = true
      enable_backup         = false
    },
    packages = {
      noncurrent_transition = 14
      noncurrent_expire     = 180
      elb_logs              = false
      enable_backup         = true
    }
  }
}


module "s3_bucket_configs" {
  source   = "terraform-aws-modules/s3-bucket/aws"
  for_each = local.buckets

  bucket = "${var.ou}-${var.env}-${each.key}"

  #bucket = "${var.ou}-${var.env}-configs2"

  lifecycle_rule = [
    {
      id = "TransitionOldVersions"
      noncurrent_version_transition = {
        noncurrent_days = each.value["noncurrent_transition"]
        storage_class   = "GLACIER"
      }
      noncurrent_version_expiration = {
        noncurrent_days = each.value["noncurrent_expire"]
      }
      status = "Enabled"

    }
  ]

  attach_elb_log_delivery_policy = each.value["elb_logs"] # Required for ALB logs
  attach_lb_log_delivery_policy  = each.value["elb_logs"] # Required for ALB/NLB logs

  tags = {
    backup = each.value["enable_backup"]
  }

  versioning = {
    enabled = true
  }

  ## can't use this within a 'module', gah!  # https://github.com/hashicorp/terraform/issues/18367
  ## (s3 won't destroy nonempty buckets, though. The other resources could be destroyed, but the data shouldn't be)
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# module "s3_bucket_logs" {
#   source = "terraform-aws-modules/s3-bucket/aws"

#   bucket = "${var.ou}-${var.env}-logs2"

#   lifecycle_rule = [
#     {
#       id = "ExpireOldVersions"
#       transition = {
#         days          = 14
#         storage_class = "GLACIER"
#       }
#       expiration = {
#         days = 180
#       }
#       status = "Enabled"
#     },
#   ]

#   versioning = {
#     enabled = true
#   }

#   attach_elb_log_delivery_policy = true # Required for ALB logs
#   attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs
# }

# module "s3_bucket_backups" {
#   source = "terraform-aws-modules/s3-bucket/aws"

#   bucket = "${var.ou}-${var.env}-backups2"

#   lifecycle_rule = [
#     {
#       id = "ExpireOldVersions"
#       transition = {
#         days          = 14
#         storage_class = "GLACIER"
#       }
#       expiration = {
#         days = 180
#       }
#       status = "Enabled"
#     },
#   ]

#   versioning = {
#     enabled = true
#   }
# }

# module "s3_bucket_packages" {
#   source = "terraform-aws-modules/s3-bucket/aws"

#   bucket = "${var.ou}-${var.env}-packages2"

#   lifecycle_rule = [
#     {
#       id = "ExpireOldVersions"
#       transition = {
#         days          = 14
#         storage_class = "GLACIER"
#       }
#       expiration = {
#         days = 180
#       }
#       status = "Enabled"
#     },
#   ]

#   versioning = {
#     enabled = true
#   }
# }

# ##
# ## Buckets
# ##

# resource "aws_s3_bucket" "logbucket" {
#   bucket = "${var.ou}-${var.env}-logs"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket" "configbucket" {
#   bucket = "${var.ou}-${var.env}-configs"

#   lifecycle {
#     prevent_destroy = true
#   }
# }


# resource "aws_s3_bucket" "backupbucket" {
#   bucket = "${var.ou}-${var.env}-backups"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket" "packagesbucket" {
#   bucket = "${var.ou}-${var.env}-packages"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# ##
# ## Lifecycles
# ##

# resource "aws_s3_bucket_lifecycle_configuration" "logbucket" {
#   bucket = aws_s3_bucket.logbucket.id

#   rule {
#     id = "ExpireOldVersions"
#     transition {
#       days          = var.log_glacier_transition_days
#       storage_class = "GLACIER"
#     }
#     expiration {
#       days = var.log_expiration_days
#     }
#     status = "Enabled"
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "configbucket" {
#   bucket = aws_s3_bucket.configbucket.id

#   rule {
#     id = "ExpireOldVersions"
#     transition {
#       days          = var.config_glacier_transition_days
#       storage_class = "GLACIER"
#     }
#     expiration {
#       days = var.config_expiration_days
#     }
#     status = "Enabled"
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "backupbucket" {
#   bucket = aws_s3_bucket.backupbucket.id

#   rule {
#     id = "ExpireOldVersions"
#     transition {
#       days          = var.backup_glacier_transition_days
#       storage_class = "GLACIER"
#     }
#     expiration {
#       days = var.backup_expiration_days
#     }
#     status = "Enabled"
#   }

# lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "packagesbucket" {
#   bucket = aws_s3_bucket.backupbucket.id

#   rule {
#     id = "ExpireOldVersions"
#     transition {
#       days          = var.packages_glacier_transition_days
#       storage_class = "GLACIER"
#     }
#     expiration {
#       days = var.packages_expiration_days
#     }
#     status = "Enabled"
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# ##
# ## Public Blocks
# ##

# resource "aws_s3_bucket_public_access_block" "logbucket" {
#   bucket = aws_s3_bucket.logbucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_public_access_block" "configbucket" {
#   bucket = aws_s3_bucket.configbucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_public_access_block" "backupbucket" {
#   bucket = aws_s3_bucket.backupbucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_s3_bucket_public_access_block" "packagesbucket" {
#   bucket = aws_s3_bucket.packagesbucket.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# ##
# ## Logwriting Policy
# ##

# resource "aws_s3_bucket_policy" "allow_elb_write" {
#   bucket = aws_s3_bucket.logbucket.id
#   policy = data.aws_iam_policy_document.allow_elb_write.json

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# data "aws_iam_policy_document" "allow_elb_write" {
#   statement {
#     sid = "allow ap-southeast-2 elb write"
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::783225319266:root"]
#     }
#     actions = [
#       "s3:PutObject"
#     ]
#     resources = [
#       "${aws_s3_bucket.logbucket.arn}/elb/*",
#     ]
#   }

#   statement {
#     sid = "allow ap-southeast-4 elb write"
#     principals {
#       type        = "Service"
#       identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
#     }
#     actions = [
#       "s3:PutObject"
#     ]
#     resources = [
#       "${aws_s3_bucket.logbucket.arn}/elb/*",
#     ]
#   }
# }
