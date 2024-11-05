##
## IAM Roles
##

# Three kinds of IAM roles for ECS
# * Service Roles deal with registering tasks against the loadbalancer
# * Task Execution Roles deal with pulling docker images and whatnot
# * Task Roles are the perms given to the actual app containers
# I'm not really across the specific philosophical separation between Service and Task Execution Roles
#
# Other IAM roles
# * Github Actions IAM role - app-specific role for Github Actions, allowing CI deployment from Github

##
## Service Role
##

resource "aws_iam_role" "ecs_service_role" {
  name = "${var.app}-${var.app_env}-service-role"

  assume_role_policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
            "Sid": "",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": [
                    "application-autoscaling.amazonaws.com",
                    "ecs.amazonaws.com",
                    "events.amazonaws.com"
                ]
            }
    }
    ]
}
EOF
}

resource "aws_iam_policy" "alb_container_scaling" {
  name   = "${var.app}-${var.app_env}-alb-container-scaling"
  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "ec2:Describe*",
                "ec2:AuthorizeSecurityGroupIngress",
                "application-autoscaling:*",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:PutMetricAlarm",
                "ecs:DescribeServices",
                "ecs:UpdateService"
        ],
        "Resource": "*",
        "Sid": ""
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_service_scaling" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = aws_iam_policy.alb_container_scaling.arn
}

##
## Task Role
##


resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app}-${var.app_env}-task-role"

  assume_role_policy = <<-EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": [
       "ecs-tasks.amazonaws.com",
       "s3.amazonaws.com"
       ]
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

# data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
#   arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "s3_assets_bucket_rw" {
  #count  = var.s3_assets_bucket != "" ? 1 : 0   # just make the policy anyway, even if the bucket doesn't exist
  name   = "${var.app}-${var.app_env}-s3-assets-rw"
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": [
              "arn:aws:s3:::${local.s3_assets_bucket}",
              "arn:aws:s3:::${local.s3_assets_bucket}/*"
            ],
            "Sid": "ReadWriteOwnAssetsBucket"
        }
        ]
    }
EOF
}

resource "aws_iam_role_policy_attachment" "s3_assets_bucket_rw" {
  #count      = var.s3_assets_bucket != "" ? 1 : 0
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_assets_bucket_rw.arn
}

resource "aws_iam_policy" "s3_external_bucket_rw" {
  count  = var.s3_external_bucket != "" ? 1 : 0
  name   = "${var.app}-${var.app_env}-s3-external-rw-${var.s3_external_bucket}"
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:*",]
            "Resource": [
              "arn:aws:s3:::${var.s3_external_bucket}",
              "arn:aws:s3:::${var.s3_external_bucket}/*"
            ],
            "Sid": "ReadWriteExternalBucket"
        }
        ]
    }
EOF
}

resource "aws_iam_role_policy_attachment" "s3_external_bucket_rw" {
  count      = var.s3_external_bucket != "" ? 1 : 0
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_assets_bucket_rw.arn
}


##
## Task Execution Role
##

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app}-${var.app_env}-task-execution-role"

  assume_role_policy = <<-EOF
{
    "Version": "2012-10-17", 
    "Statement": [
        {
        "Principal": {
            "Service": [
                "ecs-tasks.amazonaws.com",
                "s3.amazonaws.com"
            ]
        },
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Sid": ""
        }
   ]
}
EOF
}

# premade AWS policy for ECS
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-ecs-actions" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# premade AWS policy allows remote cnx to fargate containers
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-ssm-access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# lets the container engine read env/config files from s3
resource "aws_iam_policy" "read_ecs_taskenv" {
  name   = "${var.app}-${var.app_env}-read-cfg"
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Action": "s3:GetObject",
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::${var.s3_configs_bucket}/ecs/${var.app}/${var.app_env}/task.env",
            "Sid": ""
        },
        {
            "Action": "s3:GetBucketLocation",
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::${var.s3_configs_bucket}",
            "Sid": ""
        }
        ]
    }
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-s3-readconfig" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.read_ecs_taskenv.arn
}




##
## App-specific Role for Github Actions to assume
##

# This was originally meant to be a single role to handle all envs,
# but it will be easier to have a single role for each env,
# and then on the ECR repo allow roles from foreign accounts to push/pull
# so... if we have a git repo specified, always create this role
# (this will create multiple identical roles when we have multiple envs
# in the same account (eg stag/test/dev all in the dev account))

resource "aws_iam_role" "github_actions_cicd" {
  count = var.github_repo != "" ? 1 : 0
  name  = "${var.app}-${var.app_env}-github-actions"

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

resource "aws_iam_policy" "github_actions_pull_configs" {
  count  = var.github_repo != "" ? 1 : 0
  name   = "${var.app}-${var.app_env}-pull-configs"
  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${var.s3_configs_bucket}/build/${var.app}*"
        }
        ]
    }
EOF
}

resource "aws_iam_role_policy_attachment" "github_actions_pull_configs" {
  count      = var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.github_actions_cicd[0].name
  policy_arn = aws_iam_policy.github_actions_pull_configs[0].id
}

data "aws_iam_policy_document" "ecr_push_and_ecs_update" {
  statement {
    sid    = "DockerLogin"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
  statement {
    sid    = "ECRRepoPush"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]

    resources = [var.create_ecr_repo ? aws_ecr_repository.app[0].arn : var.ecr_foreign_repo_arn]
  }
  statement {
    sid    = "ECSUpdateService"
    effect = "Allow"

    actions = [
      "ecs:UpdateService"
    ]

    resources = ["arn:aws:ecs:${var.aws_region}:${var.aws_account_id}:service/${basename(var.ecs_cluster_arn)}/${var.app}*"]
  }
}

resource "aws_iam_policy" "github_actions_update_service" {
  count  = var.github_repo != "" ? 1 : 0
  name   = "${var.app}-${var.app_env}-update-service"
  policy = data.aws_iam_policy_document.ecr_push_and_ecs_update.json
}

resource "aws_iam_role_policy_attachment" "github_actions_update_service" {
  count      = var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.github_actions_cicd[0].name
  policy_arn = aws_iam_policy.github_actions_update_service[0].id
}
