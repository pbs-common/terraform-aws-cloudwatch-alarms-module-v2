module "alarm" {
  source = "../.."

  name = "test-app-existing-sns"

  # Exercises the naming and notification overrides:
  #
  #  - "adopted" notifies a topic that already exists and carries a name this module would not
  #    generate. This is the shape used when migrating alarms that predate the module, where the
  #    name is referenced elsewhere (dashboards, runbooks) and must not change.
  #  - "shared-and-slack" pairs the same existing topic with a Slack channel, so its alarm actions
  #    are the union of the caller's ARN and the topic this module creates.
  #  - "log-error" is a log-metric alarm that also pins its filter name, and notifies the existing
  #    topic on recovery only.
  #
  # Note: CloudWatch does not validate that a dimension's resource exists, so this example does not
  # provision an ALB. Those alarms sit in INSUFFICIENT_DATA, which keeps the example cheap.
  alarms = [
    {
      name                = "adopted"
      alarm_name          = "test-app-existing-sns-adopted-legacy-name"
      description         = "Alarm if ALB target response time exceeds 1s"
      metric_name         = "TargetResponseTime"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 1
      alarm_period        = 300
      alarm_statistic     = "Average"
      comparison_operator = "GreaterThanThreshold"
      alarm_actions       = [aws_sns_topic.existing.arn]
      ok_actions          = [aws_sns_topic.existing.arn]
    },
    {
      name                = "shared-and-slack"
      description         = "Alarm if ALB 5xx responses exceed 10 in 5 minutes"
      slack_channel_id    = "C0123456789"
      metric_name         = "HTTPCode_Target_5XX_Count"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 10
      alarm_period        = 300
      alarm_statistic     = "Sum"
      comparison_operator = "GreaterThanThreshold"
      alarm_actions       = [aws_sns_topic.existing.arn]
    },
    {
      name               = "log-error"
      filter_name        = "test-app-existing-sns-log-error-legacy-filter"
      description        = "Alarm if more than 5 errors in 1 minute"
      log_group_name     = aws_cloudwatch_log_group.this.name
      pattern            = "ERROR"
      metric_name        = "error-count"
      metric_namespace   = "test-app-existing-sns"
      alarm_threshold    = 5
      alarm_period       = 60
      alarm_statistic    = "Sum"
      treat_missing_data = "notBreaching"
      ok_actions         = [aws_sns_topic.existing.arn]
    }
  ]

  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
}

# Stands in for a topic owned outside this module — a shared per-product ops topic, say.
resource "aws_sns_topic" "existing" {
  name = "test-app-existing-sns-ops"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/existing-sns"
}