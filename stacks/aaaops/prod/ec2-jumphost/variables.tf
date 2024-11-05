variable "instance_type" {
  description = "EC2 instance type. Ensure it matches the AMI's cpu architecture (x96/ARM)"
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