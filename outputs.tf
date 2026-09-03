output "arns" {
  description = "ARN of the alarm provisioned"
  value       = { for key, alarm in aws_cloudwatch_metric_alarm.alarm : key => alarm.arn }
}

output "names" {
  description = "Name of the alarm provisioned"
  value       = { for key, alarm in aws_cloudwatch_metric_alarm.alarm : key => alarm.alarm_name }
}

output "log_metric_filter_names" {
  description = "Name of the log metric filter provisioned for each log-metric alarm. Alarms on AWS-published metrics are absent from this map."
  value       = { for key, filter in aws_cloudwatch_log_metric_filter.filter : key => filter.name }
}
