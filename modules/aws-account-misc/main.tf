# This modue is for small account-wide settings in AWS that don't belong in specific resource stacks
# Larger common services (eg: VPCs) should be in their own stacks

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


##
## ECS
##

# This service-linked-role is a single role for the whole account - as it serves multiple clusters, it doesn't belong in a cluster module
# the role is required to allow ECS to manage... the clusters you define... in ECS. wat?
resource "aws_iam_service_linked_role" "ecs_service_linked_role" {
  aws_service_name = "ecs.amazonaws.com"
}

##
## Github Connection
##

resource "aws_iam_openid_connect_provider" "github_oidc_provider" {

  client_id_list = ["sts.amazonaws.com"]

  url = "https://token.actions.githubusercontent.com"

  thumbprint_list = var.github_oidc_thumprints
}

##
## RDS
##

# This monitoring role is required for 'enhanced monitoring' in RDS, and is an
# account thing, not a db thing, it seems. It is automatically created the 
# first time you clickops install a db in the web console...
# ... so we create a similar one here because we're not always going to be
# clickops'ing the first RDS instance in an account

resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"

  assume_role_policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "monitoring.rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonRDSEnhancedMonitoringRole" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

##
## SSO Permissions Set policies
##

# SSO permissions sets can only adopt custom policies by name, if those names
# are in the target account

# NOTE: the Permissions Sets that call these policies are configured in
# cloudformation templates, as they are provisioned in the AWS Management 
# Account, which is not set up for Terraform

resource "aws_iam_policy" "sso_developer_rw" {
  name        = "sso-developer-rw"
  description = "For use with SSO - allows write/execute ECS tasks and other dev-related items, to be paired with a ReadOnly policy for general AWS access"

  # add more as required
  # TODO: maybe s3 configs bucket?
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ECSTaskExecute"
        Action = [
          "ecs:ExecuteCommand",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "S3ObjectWrite"
        Action = [
          "s3:*Object"
        ]
        Effect = "Allow"
        Resource = "*"
        # TODO: add a condition to stop write access to a (generic) backup bucket s3://*backup/
        # to busy with other stuff at the moment, and the AWS docs aren't clear on this specific pattern
        # Condition = {
        #   test = "ArnNotLike"

        # }
      }
    ]
  })

}

##
## SNS alert policy (email subscription needs manual confirmation)
##

resource "aws_sns_topic" "admin_alert_mail" {
  name = "admin-mail"
}

resource "aws_sns_topic_subscription" "admin_alert_mail" {
  for_each  = toset(var.sns_admin_alert_mail_addresses)
  topic_arn = aws_sns_topic.admin_alert_mail.arn
  protocol  = "email"
  endpoint  = each.value
}


resource "aws_sns_topic" "admin_alert_sms" {
  name = "admin-sms"
}

# might need more work for Australia https://docs.aws.amazon.com/sns/latest/dg/sns-supported-regions-countries.html
resource "aws_sns_topic_subscription" "admin_alert_sms" {
  for_each  = toset(var.sns_admin_alert_sms_numbers)
  topic_arn = aws_sns_topic.admin_alert_sms.arn
  protocol  = "email"
  endpoint  = each.value
}