variable "name" {
  description = "Name of the alarm being created. Defaults to product if null."
  default     = null
  type        = string
}

variable "slack_team_id" {
  description = "Slack team ID for AWS Chatbot integration"
  type        = string
  default     = "T0Y7JC3PF"
}

variable "chatbot_role_arn" {
  description = "ARN of the IAM role for AWS Chatbot"
  type        = string
  default     = null
}

variable "alarms" {
  description = <<EOT
List of CloudWatch alert configurations for Slack notifications.

Each alarm is one of two kinds:

1. Log-metric alarm: set `log_group_name` and `pattern`. A log metric filter is created that
   publishes `metric_name` in `metric_namespace`, and the alarm is created against it.
2. AWS-published metric alarm: omit both `log_group_name` and `pattern`. No log metric filter is
   created; the alarm points directly at an existing AWS metric (e.g. `TargetResponseTime` in
   `AWS/ApplicationELB`). Use `dimensions` to scope it to a specific resource.

Each object supports the following attributes:
- name: (string) Unique name for the alert
- description: (string) Description of the alarm
- slack_channel_id: (optional, string) Slack channel ID to send notifications to. Omit or set to "" to skip SNS/Chatbot. Defaults to ""
- log_group_name: (optional, string) CloudWatch log group to monitor. Required for log-metric alarms, omit for AWS-published metrics
- pattern: (optional, string) Filter pattern for log events https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html. Required for log-metric alarms, omit for AWS-published metrics
- metric_value: (optional, string) Value to publish to the metric when the pattern matches. Log-metric alarms only. Defaults to "1"
- metric_name: (string) Name of the metric. The metric emitted by the filter for log-metric alarms, or the AWS metric name (e.g. "TargetResponseTime") for AWS-published metrics
- metric_namespace: (string) Namespace of the metric (e.g. "my-app" or "AWS/ApplicationELB")
- dimensions: (optional, map(string)) Dimensions to scope the metric to (e.g. { LoadBalancer = "app/my-alb/0123456789abcdef" }). AWS-published metrics only
- alarm_threshold: (number) Threshold for triggering the alarm
- alarm_period: (number) Period (in seconds) over which data is evaluated
- alarm_statistic: (optional, string) Statistic to apply to the metric. Possible values: "Sum", "Average", "Minimum", "Maximum", "SampleCount". Set exactly one of alarm_statistic or extended_statistic
- extended_statistic: (optional, string) Percentile statistic to apply to the metric (e.g. "p95"). Set exactly one of alarm_statistic or extended_statistic
- comparison_operator: (optional, string) How the metric is compared to the threshold. Possible values: "GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold". Defaults to "GreaterThanOrEqualToThreshold"
- evaluation_periods: (optional, number) Number of periods over which data is compared to the threshold. Defaults to 1
- treat_missing_data: (optional, string) How to treat missing data. Possible values: "breaching", "notBreaching", "ignore", "missing". Defaults to "missing"

Log-metric alarm:

```hcl
{
  name               = "error"
  description        = "Alarm if more than 5 errors in 1 minute"
  slack_channel_id   = "C0123456789"
  log_group_name     = "/ecs/my-app"
  pattern            = "ERROR"
  metric_name        = "error-count"
  metric_namespace   = "my-app"
  alarm_threshold    = 5
  alarm_period       = 60
  alarm_statistic    = "Sum"
  treat_missing_data = "notBreaching"
}
```

AWS-published metric alarm:

```hcl
{
  name                = "target-response-time"
  description         = "Alarm if ALB p95 target response time exceeds 1s for 2 periods"
  slack_channel_id    = "C0123456789"
  metric_name         = "TargetResponseTime"
  metric_namespace    = "AWS/ApplicationELB"
  dimensions          = { LoadBalancer = "app/my-alb/0123456789abcdef" }
  alarm_threshold     = 1
  alarm_period        = 300
  extended_statistic  = "p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
}
```
EOT

  type = list(object({
    name             = string
    description      = string
    slack_channel_id = optional(string, "")

    # Log-metric mode. Omit both log_group_name and pattern for AWS-published metrics.
    log_group_name = optional(string)
    pattern        = optional(string)
    metric_value   = optional(string, "1")

    # Metric identity
    metric_name      = string
    metric_namespace = string
    dimensions       = optional(map(string))

    # Alarm behaviour
    alarm_threshold     = number
    alarm_period        = number
    alarm_statistic     = optional(string)
    extended_statistic  = optional(string)
    comparison_operator = optional(string, "GreaterThanOrEqualToThreshold")
    evaluation_periods  = optional(number, 1)
    treat_missing_data  = optional(string, "missing")
  }))
  default = []

  validation {
    condition     = length(distinct([for alarm in var.alarms : alarm.name])) == length(var.alarms)
    error_message = "Each alarm name must be unique."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : (alarm.log_group_name == null) == (alarm.pattern == null)])
    error_message = "log_group_name and pattern must both be set (log-metric alarm) or both be omitted (AWS-published metric alarm)."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : (alarm.alarm_statistic == null) != (alarm.extended_statistic == null)])
    error_message = "Set exactly one of alarm_statistic or extended_statistic."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : contains(["Sum", "Average", "Minimum", "Maximum", "SampleCount"], coalesce(alarm.alarm_statistic, "Sum"))])
    error_message = "The alarm_statistic attribute must be one of [Sum, Average, Minimum, Maximum, SampleCount]."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : can(regex("^p\\d{1,2}(\\.\\d{1,2})?$", coalesce(alarm.extended_statistic, "p95")))])
    error_message = "The extended_statistic attribute must be a percentile between p0 and p99.99 (e.g. p95)."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], alarm.comparison_operator)])
    error_message = "The comparison_operator attribute must be one of [GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold, LessThanOrEqualToThreshold]."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : contains(["breaching", "notBreaching", "ignore", "missing"], alarm.treat_missing_data)])
    error_message = "The treat_missing_data attribute must be one of [breaching, notBreaching, ignore, missing]."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : alarm.dimensions == null || alarm.log_group_name == null])
    error_message = "The dimensions attribute is only supported for AWS-published metric alarms (those without log_group_name and pattern)."
  }
}