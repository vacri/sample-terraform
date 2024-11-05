
variable "github_oidc_thumprints" {
  type = list(string)
  default = [
    "1234567890",
    "0987654321"
  ]
}

variable "sns_admin_alert_mail_addresses" {
  type    = list(string)
  default = []
}

variable "sns_admin_alert_sms_numbers" {
  type    = list(string)
  default = []
}