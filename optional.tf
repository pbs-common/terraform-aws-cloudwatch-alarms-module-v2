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
- alarm_name: (optional, string) Full CloudWatch alarm name, used verbatim. Set this to adopt an alarm that already exists under a name this module would not generate — for example when migrating existing Terraform-managed alarms into this module with `moved` blocks, or when the name is referenced elsewhere (dashboards, runbooks). When omitted, the name is `<name>-<environment>-<alarm name>-alarm`
- filter_name: (optional, string) Full log metric filter name, used verbatim. Log-metric alarms only. When omitted, the name is `<name>-<environment>-<alarm name>-filter`
- description: (string) Description of the alarm
- slack_channel_id: (optional, string) Slack channel ID to send notifications to. Omit or set to "" to skip SNS/Chatbot. Defaults to ""
- alarm_actions: (optional, list(string)) ARNs of existing targets (e.g. an SNS topic shared across a product) notified when the alarm enters ALARM. Combined with the topic this module creates when `slack_channel_id` is set, so an alarm can page an existing topic and post to Slack
- ok_actions: (optional, list(string)) ARNs of existing targets notified when the alarm returns to OK. Explicit only — a topic created by this module is never added here, because it exists to deliver alarm notifications, not recoveries
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

Alarm on an existing SNS topic, under a name this module does not generate:

```hcl
{
  name                = "primary-db-connections"
  alarm_name          = "my-app-prod-primary-db-connections"
  description         = "Too many connections to the primary DB"
  metric_name         = "DatabaseConnections"
  metric_namespace    = "AWS/RDS"
  dimensions          = { DBClusterIdentifier = "my-app-prod-cluster" }
  alarm_threshold     = 50
  alarm_period        = 60
  alarm_statistic     = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = ["arn:aws:sns:us-east-1:111122223333:my-ops-topic"]
  ok_actions          = ["arn:aws:sns:us-east-1:111122223333:my-ops-topic"]
}
```
EOT

  type = list(object({
    name        = string
    description = string

    # Naming. Set these to adopt resources that already exist under a name this module would not
    # generate; omit them to use the generated <name>-<environment>-<alarm name>-{alarm,filter}.
    alarm_name  = optional(string)
    filter_name = optional(string)

    # Notifications
    slack_channel_id = optional(string, "")
    alarm_actions    = optional(list(string))
    ok_actions       = optional(list(string))

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
    condition     = length(distinct([for alarm in var.alarms : alarm.alarm_name if alarm.alarm_name != null])) == length([for alarm in var.alarms : alarm.alarm_name if alarm.alarm_name != null])
    error_message = "Each alarm_name must be unique. CloudWatch alarm names are unique per account and region, so two alarms sharing one would fight over the same alarm."
  }

  validation {
    condition     = length(distinct([for alarm in var.alarms : alarm.filter_name if alarm.filter_name != null])) == length([for alarm in var.alarms : alarm.filter_name if alarm.filter_name != null])
    error_message = "Each filter_name must be unique."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : alarm.filter_name == null || alarm.log_group_name != null])
    error_message = "The filter_name attribute is only supported for log-metric alarms (those with log_group_name and pattern)."
  }

  validation {
    condition     = alltrue([for alarm in var.alarms : alltrue([for arn in concat(coalesce(alarm.alarm_actions, []), coalesce(alarm.ok_actions, [])) : can(regex("^arn:aws[a-z\\-]*:", arn))])])
    error_message = "Every alarm_actions and ok_actions entry must be an ARN."
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