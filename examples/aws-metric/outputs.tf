output "arn" {
  description = "ARN of the alarm provisioned"
  value       = module.alarm.arns
}

output "name" {
  description = "Name of the alarm provisioned"
  value       = module.alarm.names
}

output "log_metric_filter_name" {
  description = "Name of the log metric filter provisioned. Empty, as this example alarms on an AWS-published metric."
  value       = module.alarm.log_metric_filter_names
}