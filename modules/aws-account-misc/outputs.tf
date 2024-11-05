output "sns_admin_alert_mail_arn" {
  description = "ARN of the admin email SNS topic"
  value       = aws_sns_topic.admin_alert_mail.arn
}

output "sns_admin_alert_sms_arn" {
  description = "ARN of the admin SMS SNS topic"
  value       = aws_sns_topic.admin_alert_sms.arn
}