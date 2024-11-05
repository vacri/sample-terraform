variable "app" {
  type    = string
  default = "unset"
}

variable "ou" {
  type    = string
  default = "unset"
}

variable "env" {
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

variable "ecs_cluster_subnets" {
  type    = list(string)
  default = []
}

# TODO: maybe just do a single path, and call multiple times with for_each?
variable "efs_mounted_volume_path" {
  type    = string
  default = null
}

variable "target_security_group_ids" {
  type    = list(string)
  default = null
}

variable "efs_backup_tag" {
  description = "Tag backup = true to be picked up by a backup script"
  type        = bool
  default     = true
}

