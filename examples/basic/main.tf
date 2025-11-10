module "alarm" {
  source = "../.."

  name = "test-app-basic"

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
    }
  ]

  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/basic"
}