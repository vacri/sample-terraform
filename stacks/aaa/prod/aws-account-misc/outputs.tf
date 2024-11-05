output "sns_admin_alert_mail_arn" {
  description = "ARN of the admin email SNS topic"
  value       = module.aws-account-misc.sns_admin_alert_mail_arn
}

output "sns_admin_alert_sms_arn" {
  description = "ARN of the admin SMS SNS topic"
  value       = module.aws-account-misc.sns_admin_alert_sms_arn
}