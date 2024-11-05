variable "ou" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "app" {
  type    = string
  default = "unset"
}

variable "app_env" {
  description = "as distinct from stack env (prod/dev), the app_env can be anything (qa/uat/stag/etc)"
  type        = string
  default     = "unset"
}

variable "vpc_id" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "use_init_placeholder_image" {
  description = "Use docker image httpd:latest on port 80 instead of nominated image. Required until the app's ECR repo is populated"
  type        = bool
  default     = true
}

variable "container_image" {
  description = "Container image name, excluding the label. Should include the full URI if not a stock Dockerhub image"
  type        = string
  default     = "public.ecr.aws/aaaops/php-soe"
}

variable "container_label" {
  description = "Usually this should match the environment being deployed (dev/stag/prod/etc) rather than 'latest'"
  type        = string
  default     = "8.2"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_codes" {
  description = "allowed health check HTTP codes, called 'matcher' in the loadbalancer Target Group"
  type        = string
  default     = "200-399"
}

variable "health_check_interval" {
  type    = string
  default = "10"
}

variable "health_check_unhealthy_threshold" {
  description = "how many health check fails before destroying the container"
  type        = string
  default     = "2"
}

variable "create_ecr_repo" {
  description = "Create an ECR repo in this stack? Only one of each is required, but there is one stack per environment (dev/stag/prod/etc)"
  type        = bool
  default     = false
}

variable "ecr_repo_name" {
  description = "Name for created ECR repo. Not used unless create_ecr_repo is set to `true`. Generally will match up with container_image"
  type        = string
  default     = ""
}

variable "container_count_desired" {
  type    = number
  default = 1
}

variable "container_count_max" {
  type    = number
  default = 4
}

variable "container_count_min" {
  type    = number
  default = 1
}

variable "scale_up_count" {
  type    = number
  default = 3
}

variable "scale_down_count" {
  type    = number
  default = 1
}

variable "s3_configs_bucket" {
  type    = string
  default = ""
}

# variable "s3_assets_bucket" {
#   type    = string
#   default = ""
# }

# if you want read/write to a bucket not defined in this stack, nominate it here
variable "s3_external_bucket" {
  type    = string
  default = ""
}

variable "github_repo" {
  type    = string
  default = ""
}
variable "github_org" {
  type    = string
  default = "YourGithubOrgName"
}

variable "alb_https_listener_arn" {
  type = string
}

variable "alb_https_listener_priority" {
  description = "Priority must be unique for this ALB listener"
  type        = number
  default     = 500
}

variable "host_headers" {
  description = "List of host headers (domain names) to forward to container"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_subnets" {
  type    = list(string)
  default = []
}

variable "ecs_log_driver" {
  type    = string
  default = "awslogs"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

# number must be selected from a list: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0 (0 = never expire)
variable "log_retention_in_days" {
  type    = number
  default = 60
}

# 256 (.25 vCPU) - Available memory values: 0.5GB, 1GB, 2GB
# 512 (.5 vCPU) - Available memory values: 1GB, 2GB, 3GB, 4GB
# 1024 (1 vCPU) - Available memory values: 2GB, 3GB, 4GB, 5GB, 6GB, 7GB, 8GB
# 2048 (2 vCPU) - Available memory values: Between 4GB and 16GB in 1GB increments
# 4096 (4 vCPU) - Available memory values: Between 8GB and 30GB in 1GB increments
variable "container_cpu" {
  description = "CPU rating where 1024 = 1 CPU. Common settings are 256, 512, 1024, 2048, and depend on the selection for memory"
  type        = string
  default     = "256"
}

# 0.5GB, 1GB, 2GB - Available cpu values: 256 (.25 vCPU)
# 1GB, 2GB, 3GB, 4GB - Available cpu values: 512 (.5 vCPU)
# 2GB, 3GB, 4GB, 5GB, 6GB, 7GB, 8GB - Available cpu values: 1024 (1 vCPU)
# Between 4GB and 16GB in 1GB increments - Available cpu values: 2048 (2 vCPU)
# Between 8GB and 30GB in 1GB increments - Available cpu values: 4096 (4 vCPU)
#
# NOTE: use numbers rather than "xGB" or Terraform will consider it a change on every run
variable "container_memory" {
  description = "Memory rating in MB. Common settings are 0.5GB, 1GB, 2GB, 3GB, 4GB, and depend on the selection for CPU"
  type        = string
  default     = "512"
}

variable "s3_noncurrent_transition_days" {
  description = "s3 versioning transition to glacier for old copies of files in days"
  type        = string
  default     = 14
}

variable "s3_noncurrent_expiration_days" {
  description = "s3 versioning expiration for old copies of files in days"
  type        = string
  default     = 180
}

variable "create_s3_assets_bucket" {
  type    = bool
  default = false
}

variable "s3_bucket_suffix" {
  description = "Suffix for s3 bucket, in case you get a collision with someone else's bucket in the global namespace. Please start with a hypen"
  type        = string
  default     = ""
}

variable "alb_draining_period" {
  description = "How long a container will 'drain' its network connections when removed from an ELB (this affects how fast containers are swapped out/deployed). Non-prod containers are set to 0"
  type        = number
  default     = 30
}

variable "s3_task_env_key" {
  type = string
}

## Cross-account ECR / 'foreign' accounts
# Originally we planned to have just one ECR account to handle all envs. This
# requires a lot of chicanery, far more than we benefit from having a single unified repo
# It's a lot easier to manage env-dedicated repos, so we've moved to that
# To enable cross-account repos:
# * the stack hosting the repo needs to have `ecr_foreign_account_ids` list all other AWS account IDs that are allowed to pull from it
#    * this adds a permissions snippet to the ECR repo
# * the stack(s) not hosting the repo need to list the ARN of the repo in the foreign account with `ecr_foreign_repo_arn`
#    * this acts as a flag when making IAM Roles
# * permission to push/pull from CI/CD needs to be on the foreign app env's github role
# * the ECS service in the foreign app env needs permission to pull images
# I'm leaving the cross-account code in for the moment, since there's a couple of (clean) tricks that can be used for reference 
# (eg: proper way of doing AWS policies in TF, with data blocks and jsonencode() that allows some conditionals (and doesn't use json inside))
variable "ecr_foreign_account_ids" {
  description = "Allow a list of other AWS account IDs to pull images from this repo (this stack is the ecr 'host' for this app)"
  type        = list(string)
  default     = []
}
variable "ecr_foreign_repo_arn" {
  description = "ARN of the foreign ecr repo to use for push/pull/deploy of docker images (this stack is the ecr 'client' of another host stack for this app)"
  type        = string
  default     = ""
}


variable "s3_enable_current_version_transition" {
  description = "Turn on transitioning current files to a known storage class. Useful for converting to STANDARD_IA for reduced storage costs"
  type        = bool
  default     = false
}

variable "s3_current_transition_days" {
  type    = number
  default = 30 # minimum for STANDARD_IA
}

variable "s3_current_transition_storage_class" {
  type    = string
  default = "STANDARD_IA"
}

variable "s3_enable_assets_website" {
  type    = bool
  default = false
}

# example of s3 module website config block here: https://github.com/terraform-aws-modules/terraform-aws-s3-bucket/blob/v3.14.1/examples/complete/main.tf
variable "s3_website_config" {
  type = map(any)
  default = {
    index_document = "index.html"
  }
}

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone" {
  type    = string
  default = "aaa.tools"
}


variable "efs_mounted_volume_paths" {
  # see notes in main.tf/aws_efs_mount_target
  # keeping this variable as a list, in case in future we decide to figure out how to fix this
  description = "Enable EFS by putting a list of up to 3 filesystem paths"
  type        = list(string)
  default     = []
}

variable "efs_extra_writemount_security_groups" {
  description = "Allow additional external security groups to mount the EFS volumes"
  type        = list(string)
  default     = []
}

variable "efs_backup_tag" {
  description = "Tag backup = true to be picked up by a backup script"
  type        = bool
  default     = true
}

variable "s3_backup_tag" {
  description = "Tag backup = true to be picked up by a backup script"
  type        = bool
  default     = true
}