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

Integrate this module like so:

```hcl
module "alarm" {
  source = "github.com/pbs/terraform-aws-cloudwatch-alarms-module-v2?ref=x.y.z"

  name       = "test-app"
  alarms     = [
    {
      name             = "error-count-alarm"
      description      = "Alarm if more than 5 errors in 1 minute"
      slack_channel_id = "C12345678"
      log_group_name   = "/ecs/test-app-log-group-name"
      pattern          = "ERROR"
      metric_name      = "error-count"
      metric_namespace = "test-app"
      metric_value     = "1"
      alarm_threshold  = 5
      alarm_period     = 60
      alarm_statistic  = "Sum"
      treat_missing_data = "notBreaching"
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

## Adding This Version of the Module

If this repo is added as a subtree, then the version of the module should be close to the version shown here:

`x.y.z`

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.20.0 |

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
| <a name="input_alarms"></a> [alarms](#input\_alarms) | List of CloudWatch alert configurations for Slack notifications.<br/><br/>Each object supports the following attributes:<br/>- name: (string) Unique name for the alert<br/>- description: (string) Description of the alarm<br/>- slack\_channel\_id: (string) Slack channel ID to send notifications to<br/>- log\_group\_name: (string) CloudWatch log group to monitor<br/>- pattern: (string) Filter pattern for log events https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html<br/>- metric\_name: (string) Name of the custom metric<br/>- metric\_namespace: (string) Namespace for the custom metric<br/>- metric\_value: (string) Value to publish to the metric when the pattern matches (usually "1")<br/>- alarm\_threshold: (number) Threshold for triggering the alarm<br/>- alarm\_period: (number) Period (in seconds) over which data is evaluated<br/>- alarm\_statistic: (string) Statistic to apply to the metric. Possible values: "Sum", "Average", "Minimum", "Maximum", "SampleCount"<br/>- treat\_missing\_data: (string) How to treat missing data. Possible values: "breaching", "notBreaching", "ignore", "missing" | <pre>list(object({<br/>    name               = string<br/>    description        = string<br/>    slack_channel_id   = string<br/>    log_group_name     = string<br/>    pattern            = string<br/>    metric_name        = string<br/>    metric_namespace   = string<br/>    metric_value       = string<br/>    alarm_threshold    = number<br/>    alarm_period       = number<br/>    alarm_statistic    = string<br/>    treat_missing_data = string<br/>  }))</pre> | `[]` | no |
| <a name="input_chatbot_role_arn"></a> [chatbot\_role\_arn](#input\_chatbot\_role\_arn) | ARN of the IAM role for AWS Chatbot | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the alarm being created. Defaults to product if null. | `string` | `null` | no |
| <a name="input_slack_team_id"></a> [slack\_team\_id](#input\_slack\_team\_id) | Slack team ID for AWS Chatbot integration | `string` | `"T0Y7JC3PF"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arns"></a> [arns](#output\_arns) | ARN of the alarm provisioned |
| <a name="output_names"></a> [names](#output\_names) | Name of the alarm provisioned |
