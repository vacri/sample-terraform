# create a docker service on ECS/Fargate, with optional s3 assets bucket
# optional dns record

# TODO:
# * scheduled tasks (ecs version of cronjobs)
# * Cloudflare DNS (a little tricky, see notes below)
#    * this is done for s3 assets website/cdn, but not for main site
# * confirm that changes to s3 task.env file don't get stomped on if TF is rerun
# * add 'optional' ACM cert ARN to https listener
# * support for multiple environments
#   * first stack (probably prod) should create the ECR repo and github role
#   * other stacks (dev, stag, qa, whatever) should not create a repo and not make a role

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


locals {

  awslogs_group = "/ecs/${var.app}-${var.app_env}"

  # bucket suffix is in case someone else is already using the s3 bucket name (s3 is a global namespace for all users)
  s3_assets_bucket = "${var.app}-${var.app_env}-assets${var.s3_bucket_suffix}"

  # the env is put first to make prod vs non-prod more clear
  # I have had issues in the past with people not realising prod vs non-prod cdns
  s3_cdn_website_name_prefix = "${var.app_env}-cdn-${var.app}"

  container_image = var.use_init_placeholder_image ? "public.ecr.aws/aaaops/web-soe" : var.container_image
  container_label = var.use_init_placeholder_image ? "8.2" : var.container_label
  container_port  = var.use_init_placeholder_image ? 8080 : var.container_port

}

##
## ECR repo
##

resource "aws_ecr_repository" "app" {
  count                = var.create_ecr_repo ? 1 : 0
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE" # required to move tags in ECR
}

## this policy cleans up old images
## probably don't want to enable this if we're going to have multiple envs served by a single repo
# resource "aws_ecr_lifecycle_policy" "app" {
#   repository = aws_ecr_repository.app.name

#   policy = jsonencode({
#    rules = [{
#      rulePriority = 1
#      description  = "keep last 10 images"
#      action       = {
#        type = "expire"
#      }
#      selection     = {
#        tagStatus   = "any"
#        countType   = "imageCountMoreThan"
#        countNumber = 10
#      }
#    }]
#   })
# }

data "aws_iam_policy_document" "ecr_cross_account_pull" {
  # https://repost.aws/knowledge-center/secondary-account-access-ecr
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy
  statement {
    sid    = "ecr cross account pull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.ecr_foreign_account_ids
    }

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
  }
}

resource "aws_ecr_repository_policy" "ecr_cross_account_pull" {
  count      = (length(var.ecr_foreign_account_ids) > 0) && (var.create_ecr_repo) ? 1 : 0
  repository = aws_ecr_repository.app[0].name
  policy     = data.aws_iam_policy_document.ecr_cross_account_pull.json
}




##
## ECS Service
##

resource "aws_ecs_service" "app" {
  depends_on = [
    aws_iam_role.ecs_task_role,
    aws_iam_role.ecs_task_execution_role,
    aws_iam_role.ecs_service_role,
    aws_cloudwatch_log_group.app
  ]

  name                               = "${var.app}-${var.app_env}"
  cluster                            = var.ecs_cluster_arn
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = var.container_count_desired
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  enable_execute_command             = true # allows connection with AWS SSM (shelling into container). also needs TaskRole perms

  network_configuration {
    security_groups  = [aws_security_group.ecs_service.id]
    subnets          = var.ecs_cluster_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.arn
    container_name   = "${var.app}-${var.app_env}-app"
    container_port   = local.container_port
  }

  lifecycle {
    # don't use 'task_definition' here if your CI deploy style for ECS is 'update the task definition, then apply', 
    # which generates a new version of the TD each time
    # always ignore 'desired_count' - the desired count is dynamic and responds to current load
    #   (you only need desired_count when init'ing)
    #ignore_changes = [task_definition, desired_count]
    ignore_changes = [desired_count]
  }
}

resource "aws_alb_target_group" "app" {
  name        = "${var.app}-${var.app_env}-tg-${substr(uuid(), 0, 3)}"
  port        = local.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  # for non-prod environments, we set draining period to 0 (makes iteration faster)
  deregistration_delay = var.app_env != "prod" ? 0 : var.alb_draining_period

  health_check {
    healthy_threshold   = "2"
    interval            = var.health_check_interval
    protocol            = "HTTP"
    matcher             = var.health_check_codes
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  lifecycle {
    # this plus the random name suffix above are required to allow port changes on an existing setup,
    # the uuid will change every time the stack is run, so we need to ignore changes on the name. not great, but hey...
    # see https://stackoverflow.com/a/60080801
    # the alternative is to delete the rules on the https listener rules in the web console first, then rerun 'apply'
    # (not terraform as that would require destruction of the target group as well, and possibly other things)
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "aws_alb_listener_rule" "app" {
  listener_arn = var.alb_https_listener_arn
  priority     = var.alb_https_listener_priority
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app.arn
  }

  condition {
    host_header {
      values = var.host_headers
    }
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.container_count_max
  min_capacity       = var.container_count_min
  resource_id        = "service/${basename(var.ecs_cluster_arn)}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}

resource "aws_security_group" "ecs_service" {
  name   = "${var.app}-${var.app_env}-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = local.container_port
    to_port          = local.container_port
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
##
## ECS Task
##

## can't use prevent_destroy inside a module >:( so move this to the stack file
# resource "aws_s3_object" "task_env" {
#   bucket = var.s3_configs_bucket
#   key    = "ecs/${var.app}/${var.app_env}/task.env"
#   source = "${path.module}/task.env.tpl"
#   #etag   = filemd5("${path.module}/task.env.tpl")   # enable etag if you want to overwrite external changes (I think)

#   # lifecycle {
#   #   prevent_destroy = true
#   #   #ignore_changes = [  ]
#   # }
# }


# the canned IAM policy for ECS Task Execution does NOT have the perms to autocreate 
# log groups (even though marked as 'true' in the container definition below).
# however, we still want to separately create the log group, because then we can
# put an expiry date on the logs - I didn't find a mechanism to do this on log 
# groups auto-created by the container_definition
resource "aws_cloudwatch_log_group" "app" {
  name              = local.awslogs_group
  retention_in_days = var.log_retention_in_days
}


resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app}-${var.app_env}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  # setting the hostPort below to equal the containerPort "just seems to work".
  # Normally you would expect there to be a conflict if more than one container tries to bind to the host port.
  # note that the host port is also the target of the Target Group above. For the moment, it seems to be working as-is
  # with a couple of test containers on port 80. Might need to revisit this if we run into conflicts later
  # (ECS has the concept of dynamic ports, where ECS magically handles the port assignment in both the target group
  # and the docker host, but I don't see how to configure that in Terraform)
  ##"value" : "arn:aws:s3:::${var.s3_configs_bucket}/ecs/${var.app}/${var.app_env}/task.env"

  container_definitions = jsonencode(
    [
      # this merge() is to support optional EFS volumes. See HAX notes below.
      # it merges the main map with the output of a hacky coalesce() function
      merge(
        {
          name      = "${var.app}-${var.app_env}-app",
          image     = "${local.container_image}:${local.container_label}",
          essential = true
          environmentFiles = [{
            type  = "s3"
            value = "arn:aws:s3:::${var.s3_configs_bucket}/${var.s3_task_env_key}"
          }]
          logConfiguration = {
            logDriver = "awslogs",
            options = {
              awslogs-group         = "${local.awslogs_group}",
              awslogs-create-group  = "true",
              awslogs-region        = "${var.aws_region}",
              awslogs-stream-prefix = "ecs"
            }
          }
          portMappings = [
            {
              name          = "${var.app}-${var.app_env}-${local.container_port}-tcp",
              containerPort = "${local.container_port}",
              hostPort      = "${local.container_port}",
              protocol      = "tcp",
              appProtocol   = "http"
            }
          ]
          mountPoints = []
        },
        # WARNING: HAX (kinda)
        # we can't iterate with for_each or dynamic{} when we're within a jsonencode()
        # and it looks like we can't iterate using external json templates
        # Since the EFS volumes are optional AND there can be more than one, we're in a bit
        # of a pickle.
        # without for_each, we can't get the literal names of the items ["/mnt"] from the
        # object that built the resource... but we can access the *list* of paths we sent to
        # that object. We can then use the list indices to choose the results
        # WHAT'S HAPPENING HERE: we have pre-prepared config for the case where we have
        # 1, 2, or 3 EFS mount paths. We check the list of paths for number of entries, and
        # apply the relevant block. If we have 0 or 4+ entries, we get a no-op {}.
        # If you want 4+ EFS mounts... add it, I guess. And then take a good hard look in the 
        # mirror.
        # this isn't really hax, but it is a bit overcomplicated
        coalesce(
          # coalesce goes through the set of items until it hits one that doesn't fail.
          # we then merge() that with the main body of the config above
          # since I can't find out how for_each within jsonencode(), we just try a series of
          # items until we get one that doesn't fail
          length(var.efs_mounted_volume_paths) == 1 ? {
            mountPoints = [{
              containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_mounted_volume_path
              sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_volume_name
            }]
          } : null,

          length(var.efs_mounted_volume_paths) == 2 ? {
            mountPoints = [{
              containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_mounted_volume_path
              sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_volume_name
              },
              {
                containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[1]].efs_mounted_volume_path
                sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[1]].efs_volume_name
            }]
          } : null,

          length(var.efs_mounted_volume_paths) == 3 ? {
            mountPoints = [{
              containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_mounted_volume_path
              sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[0]].efs_volume_name
              },
              {
                containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[1]].efs_mounted_volume_path
                sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[1]].efs_volume_name
              },
              {
                containerPath = module.fargate_efs_submodule[var.efs_mounted_volume_paths[2]].efs_mounted_volume_path
                sourceVolume  = module.fargate_efs_submodule[var.efs_mounted_volume_paths[2]].efs_volume_name
              }
            ]
          } : null,

          {}
        )
      )
    ]
  )

  dynamic "volume" {
    # instead of each.key and each.value, dynamic blocks replace 'each' with the name
    # of the block (in this case, 'volume')
    for_each = { for k, v in module.fargate_efs_submodule : v.efs_volume_name => v.efs_volume_id }
    content {
      #name = "${var.app}-${var.env}-efs"
      name = volume.key
      efs_volume_configuration {
        file_system_id = volume.value
      }
    }
  }
}

# TODO: scheduled tasks (ecs version of cronjobs)

##
## DNS record (optional)
##

# TODO: list of domains in cloudflare, basically: [ "aaa.tools", "aaa.com.au"]
# * 'for each' domains on ALB, compare against list, and if in it, create the DNS record
#     * can't quite find the right syntax
# * this is a many-to-many setup (multiple items in domain list, multiple zones 
#   in cloudflare)
#    * might not be able to reference it cleanly - might need to have separate
#      resource entries for each zone
# * there can be multiple hostnames - eg we might have a deploy that serves 
#   prod-app.aaa.tools that then later has an aaa.com.au domain added

# data "cloudflare_zones" "aaa.tools_domain" {
#   filter {
#     name = "aaa.tools"
#   }
# }

# resource "cloudflare_record" "aaa.tools_domain" {
#   #count = "aaa.tools" in var.domains ? 1 : 0
#   for_each = local.aaa.tools_domains

#   zone_id = data.cloudflare_zones.aaa.tools_domain.zones[0].id
#   name    = each.key
#   value   = "example.com"
#   type    = "CNAME"
#   proxied = true
# }

