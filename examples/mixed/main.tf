module "alarm" {
  source = "../.."

  name = "test-app-mixed"

  # One log-metric alarm with Slack notifications, one AWS-published metric alarm without. This
  # exercises the per-alarm SNS wiring: only the first alarm gets a topic and Chatbot config.
  alarms = [
    {
      name               = "error"
      description        = "Alarm if more than 5 errors in 1 minute"
      slack_channel_id   = "C0123456789"
      log_group_name     = aws_cloudwatch_log_group.this.name
      pattern            = "ERROR"
      metric_name        = "error-count"
      metric_namespace   = "test-app"
      metric_value       = "1"
      alarm_threshold    = 5
      alarm_period       = 60
      alarm_statistic    = "Sum"
      treat_missing_data = "notBreaching"
    },
    {
      name                = "target-response-time"
      description         = "Alarm if ALB p95 target response time exceeds 1s for 2 periods"
      metric_name         = "TargetResponseTime"
      metric_namespace    = "AWS/ApplicationELB"
      dimensions          = { LoadBalancer = "app/example-alb/0123456789abcdef" }
      alarm_threshold     = 1
      alarm_period        = 300
      extended_statistic  = "p95"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
    }
  ]

  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/mixed"
}