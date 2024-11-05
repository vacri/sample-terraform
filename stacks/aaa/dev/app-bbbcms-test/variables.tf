variable "app_name" {
  type    = string
  default = "CHANGEME"
}

variable "app_env" {
  description = "Empty string will use stack env (prod/dev), otherwise specify app env (qa/uat/stag/whatever)"
  type        = string
  default     = ""
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
  type    = string
  default = "8.2"
}

variable "container_port" {
  type    = number
  default = 8080
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

variable "github_repo" {
  type    = string
  default = ""
}

variable "create_ecr_repo_and_github_role" {
  description = "Create an ECR repo and github role in this stack? Only one is required, but there is one stack per environment (dev/stag/prod/etc)"
  type        = bool
  default     = false
}

variable "ecr_repo_name" {
  description = "Name for created ECR repo. Not used unless create_ecr_repo is set to `true` AND you want a different name to the git repo. Generally will match up with container_image"
  type        = string
  default     = ""
}

variable "host_headers" {
  description = "List of host headers (domain names) to forward to container"
  type        = list(string)
  default     = []
}

variable "alb_https_listener_priority" {
  description = "Priority must be unique for this ALB listener"
  type        = number
  default     = 500
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

variable "create_s3_assets_bucket" {
  type    = bool
  default = false
}

variable "alb_draining_period" {
  description = "How long a container will 'drain' its network connections when removed from an ELB (this affects how fast containers are swapped out/deployed). Non-prod containers are set to 0"
  type        = number
  default     = 30
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