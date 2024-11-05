variable "instance_type" {
  description = "EC2 instance type. Ensure it matches the AMI's cpu architecture (x86/ARM)"
  type        = string
  default     = "t4g.nano"
}

variable "disable_api_termination" {
  description = "Enable Termination Protection (true = enabled)"
  type        = bool
  default     = true
}

variable "ec2_keypair" {
  description = "ec2 keypair, not made by this stack"
  type        = string
  nullable    = false
}

variable "ami_filter_strings" {
  type    = list(string)
  default = ["debian-12-arm64-*"]
}

variable "ami_owners" {
  type    = list(string)
  default = ["136693071363"] # Debian official AMI owner
}


variable "ec2_root_volume_type" {
  type    = string
  default = "gp3"
}

variable "ec2_root_volume_size" {
  description = "EC2 volume size in gigabytes"
  type        = number
  default     = 8 # ec2 launch default
}

variable "s3_backup_write_perms" {
  description = "Allow 'write' to s3 backup bucket. Otherwise readonly access is given (eg: for an 'ops' server, not a backups serer)"
  type        = bool
  default     = false
}

variable "ec2_nametag" {
  description = "ec2 instance name tag"
  type        = string
}

variable "backups_secrets_access" {
  description = "allow access to Secrets Manager /backups/* (ops nodes don't need this)"
  type        = bool
  default     = false
}