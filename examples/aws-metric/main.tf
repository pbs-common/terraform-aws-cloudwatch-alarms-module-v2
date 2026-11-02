module "alarm" {
  source = "../.."

  name = "test-app-aws-metric"

  # No log group or pattern is set, so no log metric filter is created. The alarm points straight
  # at a metric AWS already publishes.
  #
  # Note: CloudWatch does not validate that a dimension's resource exists, so this example does
  # not provision an ALB. The alarm sits in INSUFFICIENT_DATA, which keeps the example cheap.
  alarms = [
    {
      name                = "target-response-time"
      description         = "Alarm if ALB p95 target response time exceeds 1s for 2 periods"
      slack_channel_id    = "C0123456789"
      metric_name         = "TargetResponseTime"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 1
      alarm_period        = 300
      extended_statistic  = "p95"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "missing"
    }
  ]

  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
}