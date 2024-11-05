terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

##
## ECR public repo
##

resource "aws_ecrpublic_repository" "this" {
  repository_name = var.ecr_repo_name
}

##
## Github Actions role
##

resource "aws_iam_role" "github_actions_cicd" {
  count = var.github_repo != "" ? 1 : 0

  name = "github-actions-${var.ecr_repo_name}"

  assume_role_policy = <<-EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Principal": {
       "Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
     },
     "Effect": "Allow",
     "Condition": {
        "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
        "StringLike": {"token.actions.githubusercontent.com:sub": "repo:${var.github_org}/${var.github_repo}:*"}
     },
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "github_actions_ecr_public_rw" {
  count  = var.github_repo != "" ? 1 : 0
  name   = "ecr-public-${var.ecr_repo_name}-rw"
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ecr-public:GetAuthorizationToken",
                    "sts:GetServiceBearerToken"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ecr-public:CompleteLayerUpload",
                    "ecr-public:UploadLayerPart",
                    "ecr-public:InitiateLayerUpload",
                    "ecr-public:BatchCheckLayerAvailability",
                    "ecr-public:PutImage",
                    "ecr-public:DescribeImages",
                    "ecr-public:DescribeRepositories"
                ],
                "Resource": "arn:aws:ecr-public::${var.aws_account_id}:repository/${var.ecr_repo_name}"
            }
        ]
    }
EOF
}

# resource "aws_iam_policy" "github_actions_pull_configs" {
#   count  = var.github_repo != "" && var.s3_build_dir != "" ? 1 : 0
#   name   = "${var.app}-${var.env}-pull-configs"
#   policy = <<-EOF
#     {
#         "Version": "2012-10-17",
#         "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "s3:ListBucket",
#                 "s3:GetObject"
#             ]
#             "Resource": "arn:aws:s3:${var.s3_configs_bucket}/build/${var.ecr_repo_name}/*"
#         }
#         ]
#     }
# EOF
# }

resource "aws_iam_role_policy_attachment" "github_actions_ecr_public_rw" {
  count      = var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.github_actions_cicd[0].name
  policy_arn = aws_iam_policy.github_actions_ecr_public_rw[0].arn
}

# resource "aws_iam_role_policy_attachment" "github_actions_pull_configs" {
#   count      = var.github_repo != "" && var.s3_build_dir != "" ? 1 : 0
#   role       = aws_iam_role.github_actions_cicd[0].name
#   policy_arn = aws_iam_policy.github_actions_update_service[0].arn
# }
