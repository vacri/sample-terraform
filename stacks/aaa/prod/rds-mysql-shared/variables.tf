variable "engine" {
  description = "mariadb/mysql/postgres"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  type    = string
  default = "8.0.32"
}

# variable "major_engine_version" {
#   description = "used to determine option group"
#   nullable    = false
# }

variable "instance_class" {
  type    = string
  default = "db.t3.small"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "allow the db disk to grow to this many GB"
  type        = number
  default     = 100
}

variable "port" {
  type = number
  # force a choice here - easy to mess up a psql install by forgetting to set this
  nullable = false
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "backup_window" {
  description = "daily time, in UTC"
  type        = string
  default     = "13:10-13:40"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "maintenance_window" {
  description = "daily time, in UTC, prefixed by day"
  type        = string
  default     = "Mon:14:10-Mon:14:40"
}

variable "monitoring_interval" {
  description = "0 (disabled), 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 60
}

variable "multi_az" {
  description = "multi-az = hot failover kept ready, $$"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "docs unclear how this interacts wtih multi_az. generally we want to focus on AZ 'a'"
  type        = string
  default     = "ap-southeast-2a"
}


variable "parameters" {
  type    = list(map(string))
  default = null
}

variable "options" {
  type    = map(any)
  default = null
}

variable "storage_type" {
  description = "don't use io1 unless you have $$"
  type        = string
  default     = "gp3"
}

variable "storage_throughput" {
  description = "125 is baseline for gp3. extra = $$"
  type        = number
  default     = 125
}

variable "iops" {
  description = "3000 is baseline for gp3. extra = $$"
  type        = number
  default     = 3000
}

variable "performance_insights_enabled" {
  description = "not available for mysql on t2.small, t3.small, t4g.small or smaller. no restrictions for psql"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "set additional tags, in particular the tag to enable the backup script"
  type        = map(string)
  default = {
    rds-backup = "true"
  }
}