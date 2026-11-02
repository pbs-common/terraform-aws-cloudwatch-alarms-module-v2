output "arn" {
  description = "ARN of the alarm provisioned"
  value       = module.alarm.arns
}

output "name" {
  description = "Name of the alarm provisioned"
  value       = module.alarm.names
}

output "log_metric_filter_name" {
  description = "Name of the log metric filter provisioned"
  value       = module.alarm.log_metric_filter_names
}

output "existing_topic_arn" {
  description = "ARN of the topic that stands in for one owned outside this module"
  value       = aws_sns_topic.existing.arn
}