variable "ou" {
  type    = string
  default = "aaa"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "aws_account_id" {
  type    = string
  default = "123456789012"
}
variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}
variable "cost_centre" {
  type    = string
  default = "3230"
}
variable "cloudflare_account_id" {
  type    = string
  default = "1234567890deadg00d123456789012"
}
variable "github_org" {
  type    = string
  default = "YourGithubOrgName"
}

variable "sns_admin_alert_mail_addresses" {
  type    = list(string)
  default = ["sysadmin@aaa.com.au"]
}