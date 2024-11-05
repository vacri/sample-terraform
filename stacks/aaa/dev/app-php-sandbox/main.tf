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

locals {
  ecr_repo_name     = var.ecr_repo_name != "" ? var.ecr_repo_name : var.github_repo
  app_env           = var.app_env != "" ? var.app_env : var.env
  s3_configs_bucket = "${var.ou}-${var.env}-configs"
}

# data "aws_availability_zones" "available" {
# }

data "terraform_remote_state" "fargate_cluster" {
  backend = "s3"
  config = {
    bucket = "aaa-terraform"
    key    = "${var.ou}/${var.env}/fargate-cluster-shared/terraform.tfstate"
    region = var.aws_region
  }
}

# task.env file is not part of the fargate app module as we can't
# use prevent_destroy inside modules >:(
# TO DESTROY the stack, rm this object from state first:
#       make rm resource=aws_s3_object.task_env
resource "aws_s3_object" "task_env" {
  bucket = local.s3_configs_bucket
  key    = "ecs/${var.app_name}/${local.app_env}/task.env"
  source = "${path.module}/../../../../templates/ecs/task.env.template"
  #etag   = filemd5("${path.module}/task.env.tpl")   # enable etag if you want to overwrite external changes (I think)

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags, tags_all]
  }
}

module "fargate_web_app" {
  source  = "../../../../modules/fargate-web-app"
  ou      = var.ou
  env     = var.env
  app_env = local.app_env

  # code/service config
  app                        = var.app_name
  github_repo                = var.github_repo
  use_init_placeholder_image = var.use_init_placeholder_image

  ecr_repo_name                   = local.ecr_repo_name
  create_ecr_repo_and_github_role = var.create_ecr_repo_and_github_role
  create_s3_assets_bucket         = var.create_s3_assets_bucket

  # task/container config
  container_image = var.container_image
  container_label = var.container_label
  container_port  = var.container_port

  container_count_min     = var.container_count_min
  container_count_max     = var.container_count_max
  container_count_desired = var.container_count_desired

  health_check_path                = var.health_check_path
  health_check_codes               = var.health_check_codes
  health_check_interval            = var.health_check_interval
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  s3_configs_bucket = local.s3_configs_bucket # task,env file lives here
  s3_task_env_key   = aws_s3_object.task_env.id

  # network and cluster config
  alb_https_listener_arn      = data.terraform_remote_state.fargate_cluster.outputs.alb_https_listener_arn
  alb_https_listener_priority = var.alb_https_listener_priority
  alb_draining_period         = var.alb_draining_period
  host_headers                = var.host_headers

  aws_account_id      = var.aws_account_id
  aws_region          = var.aws_region
  vpc_id              = data.terraform_remote_state.fargate_cluster.outputs.vpc_id
  ecs_cluster_arn     = data.terraform_remote_state.fargate_cluster.outputs.cluster_arn
  ecs_cluster_subnets = data.terraform_remote_state.fargate_cluster.outputs.cluster_subnets

}
