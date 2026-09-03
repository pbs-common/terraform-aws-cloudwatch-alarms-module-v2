# PBS TF CloudWatch Alarms Module v2

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-cloudwatch-alarms-module-v2?ref=x.y.z
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
  source = "github.com/pbs/terraform-aws-cloudwatch-alarms-module-v2?ref=x.y.z"

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

`x.y.z`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs
