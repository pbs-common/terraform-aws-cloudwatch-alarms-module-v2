# PBS TF CloudWatch Alarms Module v2

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-cloudwatch-alarms-module-v2?ref=1.0.2
```

### Alternative Installation Methods

More information can be found on these install methods and more in [the documentation here](./docs/general/install).

## Usage

This module provisions multiple CloudWatch alarms and can send notifications to Slack via SNS topics and AmazonQ.

It is an opinionated module that will configure CloudWatch alarms with as little manual configuration as possible. See the examples located in the [examples folder](/examples) to see what kind of resources are supported.

Each entry in `alarms` is one of two kinds, and a single list can mix them:

- **Log-metric alarm** — set `log_group_name` and `pattern`. The module creates a log metric filter that publishes `metric_name` in `metric_namespace`, then alarms on it.
- **AWS-published metric alarm** — omit both `log_group_name` and `pattern`. No log metric filter is created; the alarm points directly at a metric AWS already publishes, such as `TargetResponseTime` in `AWS/ApplicationELB`. Use `dimensions` to scope it to a specific resource.

Integrate this module like so:

```hcl
module "alarm" {
  source = "github.com/pbs/terraform-aws-cloudwatch-alarms-module-v2?ref=1.0.2"

  name = "test-app"
  alarms = [
    # Log-metric alarm
    {
      name               = "error-count-alarm"
      description        = "Alarm if more than 5 errors in 1 minute"
      slack_channel_id   = "C12345678"
      log_group_name     = "/ecs/test-app-log-group-name"
      pattern            = "ERROR"
      metric_name        = "error-count"
      metric_namespace   = "test-app"
      metric_value       = "1"
      alarm_threshold    = 5
      alarm_period       = 60
      alarm_statistic    = "Sum"
      treat_missing_data = "notBreaching"
    },
    # AWS-published metric alarm
    {
      name                = "target-response-time-alarm"
      description         = "Alarm if ALB p95 target response time exceeds 1s for 2 periods"
      slack_channel_id    = "C12345678"
      metric_name         = "TargetResponseTime"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/test-app-alb/0123456789abcdef" }
      alarm_threshold     = 1
      alarm_period        = 300
      extended_statistic  = "p95"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
    }
  ]

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo

  # Optional Parameters

}
```

Set exactly one of `alarm_statistic` (`Sum`, `Average`, `Minimum`, `Maximum`, `SampleCount`) or `extended_statistic` (a percentile, e.g. `p95`) per alarm. `comparison_operator` defaults to `GreaterThanOrEqualToThreshold` and `evaluation_periods` to `1`.

Note that CloudWatch does not validate that the resource named in `dimensions` exists — a wrong dimension value produces an alarm that silently never fires.

## Adding This Version of the Module

If this repo is added as a subtree, then the version of the module should be close to the version shown here:

`1.0.2`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_chatbot_slack_channel_configuration.slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/chatbot_slack_channel_configuration) | resource |
| [aws_cloudwatch_log_metric_filter.filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |
| [aws_cloudwatch_metric_alarm.alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.common_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (sharedtools, dev, staging, qa, prod) | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization using this module. Used to prefix tags so that they are easily identified as being from your organization | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Tag used to group resources according to owner | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Tag used to point to the repo using this module | `string` | n/a | yes |
| <a name="input_alarms"></a> [alarms](#input\_alarms) | List of CloudWatch alert configurations for Slack notifications.<br/><br/>Each alarm is one of two kinds:<br/><br/>1. Log-metric alarm: set `log_group_name` and `pattern`. A log metric filter is created that<br/>   publishes `metric_name` in `metric_namespace`, and the alarm is created against it.<br/>2. AWS-published metric alarm: omit both `log_group_name` and `pattern`. No log metric filter is<br/>   created; the alarm points directly at an existing AWS metric (e.g. `TargetResponseTime` in<br/>   `AWS/ApplicationELB`). Use `dimensions` to scope it to a specific resource.<br/><br/>Each object supports the following attributes:<br/>- name: (string) Unique name for the alert<br/>- description: (string) Description of the alarm<br/>- slack\_channel\_id: (optional, string) Slack channel ID to send notifications to. Omit or set to "" to skip SNS/Chatbot. Defaults to ""<br/>- log\_group\_name: (optional, string) CloudWatch log group to monitor. Required for log-metric alarms, omit for AWS-published metrics<br/>- pattern: (optional, string) Filter pattern for log events https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html. Required for log-metric alarms, omit for AWS-published metrics<br/>- metric\_value: (optional, string) Value to publish to the metric when the pattern matches. Log-metric alarms only. Defaults to "1"<br/>- metric\_name: (string) Name of the metric. The metric emitted by the filter for log-metric alarms, or the AWS metric name (e.g. "TargetResponseTime") for AWS-published metrics<br/>- metric\_namespace: (string) Namespace of the metric (e.g. "my-app" or "AWS/ApplicationELB")<br/>- dimensions: (optional, map(string)) Dimensions to scope the metric to (e.g. { LoadBalancer = "app/my-alb/0123456789abcdef" }). AWS-published metrics only<br/>- alarm\_threshold: (number) Threshold for triggering the alarm<br/>- alarm\_period: (number) Period (in seconds) over which data is evaluated<br/>- alarm\_statistic: (optional, string) Statistic to apply to the metric. Possible values: "Sum", "Average", "Minimum", "Maximum", "SampleCount". Set exactly one of alarm\_statistic or extended\_statistic<br/>- extended\_statistic: (optional, string) Percentile statistic to apply to the metric (e.g. "p95"). Set exactly one of alarm\_statistic or extended\_statistic<br/>- comparison\_operator: (optional, string) How the metric is compared to the threshold. Possible values: "GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold". Defaults to "GreaterThanOrEqualToThreshold"<br/>- evaluation\_periods: (optional, number) Number of periods over which data is compared to the threshold. Defaults to 1<br/>- treat\_missing\_data: (optional, string) How to treat missing data. Possible values: "breaching", "notBreaching", "ignore", "missing". Defaults to "missing"<br/><br/>Log-metric alarm:<pre>hcl<br/>{<br/>  name               = "error"<br/>  description        = "Alarm if more than 5 errors in 1 minute"<br/>  slack_channel_id   = "C0123456789"<br/>  log_group_name     = "/ecs/my-app"<br/>  pattern            = "ERROR"<br/>  metric_name        = "error-count"<br/>  metric_namespace   = "my-app"<br/>  alarm_threshold    = 5<br/>  alarm_period       = 60<br/>  alarm_statistic    = "Sum"<br/>  treat_missing_data = "notBreaching"<br/>}</pre>AWS-published metric alarm:<pre>hcl<br/>{<br/>  name                = "target-response-time"<br/>  description         = "Alarm if ALB p95 target response time exceeds 1s for 2 periods"<br/>  slack_channel_id    = "C0123456789"<br/>  metric_name         = "TargetResponseTime"<br/>  metric_namespace    = "AWS/ApplicationELB"<br/>  dimensions          = { LoadBalancer = "app/my-alb/0123456789abcdef" }<br/>  alarm_threshold     = 1<br/>  alarm_period        = 300<br/>  extended_statistic  = "p95"<br/>  comparison_operator = "GreaterThanThreshold"<br/>  evaluation_periods  = 2<br/>}</pre> | <pre>list(object({<br/>    name             = string<br/>    description      = string<br/>    slack_channel_id = optional(string, "")<br/><br/>    # Log-metric mode. Omit both log_group_name and pattern for AWS-published metrics.<br/>    log_group_name = optional(string)<br/>    pattern        = optional(string)<br/>    metric_value   = optional(string, "1")<br/><br/>    # Metric identity<br/>    metric_name      = string<br/>    metric_namespace = string<br/>    dimensions       = optional(map(string))<br/><br/>    # Alarm behaviour<br/>    alarm_threshold     = number<br/>    alarm_period        = number<br/>    alarm_statistic     = optional(string)<br/>    extended_statistic  = optional(string)<br/>    comparison_operator = optional(string, "GreaterThanOrEqualToThreshold")<br/>    evaluation_periods  = optional(number, 1)<br/>    treat_missing_data  = optional(string, "missing")<br/>  }))</pre> | `[]` | no |
| <a name="input_chatbot_role_arn"></a> [chatbot\_role\_arn](#input\_chatbot\_role\_arn) | ARN of the IAM role for AWS Chatbot | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the alarm being created. Defaults to product if null. | `string` | `null` | no |
| <a name="input_slack_team_id"></a> [slack\_team\_id](#input\_slack\_team\_id) | Slack team ID for AWS Chatbot integration | `string` | `"T0Y7JC3PF"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arns"></a> [arns](#output\_arns) | ARN of the alarm provisioned |
| <a name="output_log_metric_filter_names"></a> [log\_metric\_filter\_names](#output\_log\_metric\_filter\_names) | Name of the log metric filter provisioned for each log-metric alarm. Alarms on AWS-published metrics are absent from this map. |
| <a name="output_names"></a> [names](#output\_names) | Name of the alarm provisioned |
