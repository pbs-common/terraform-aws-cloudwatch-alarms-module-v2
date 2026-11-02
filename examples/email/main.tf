module "alarm" {
  source = "../.."

  name = "test-app-email"

  # Exercises email_addresses:
  #
  #  - "shared-and-slack" pairs email with a Slack channel on the same module-created topic.
  #  - "email-only" has no slack_channel_id at all; the module still creates a topic for it,
  #    solely to carry the email subscription.
  #
  # Note: CloudWatch does not validate that a dimension's resource exists, so this example does not
  # provision an ALB. Both alarms sit in INSUFFICIENT_DATA, which keeps the example cheap.
  alarms = [
    {
      name                = "shared-and-slack"
      description         = "Alarm if ALB 5xx responses exceed 10 in 5 minutes"
      slack_channel_id    = "C0123456789"
      email_addresses     = ["ops-oncall@example.com"]
      metric_name         = "HTTPCode_Target_5XX_Count"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 10
      alarm_period        = 300
      alarm_statistic     = "Sum"
      comparison_operator = "GreaterThanThreshold"
    },
    {
      name                = "email-only"
      description         = "Alarm if ALB target response time exceeds 1s"
      email_addresses     = ["ops-oncall@example.com", "on-call-pager@example.com"]
      metric_name         = "TargetResponseTime"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 1
      alarm_period        = 300
      alarm_statistic     = "Average"
      comparison_operator = "GreaterThanThreshold"
    }
  ]

  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
}