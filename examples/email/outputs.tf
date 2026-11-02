output "arn" {
  description = "ARN of the alarm provisioned"
  value       = module.alarm.arns
}

output "name" {
  description = "Name of the alarm provisioned"
  value       = module.alarm.names
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic this module created for each alarm"
  value       = module.alarm.sns_topic_arns
}