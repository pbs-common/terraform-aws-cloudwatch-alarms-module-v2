resource "aws_cloudwatch_log_metric_filter" "filter" {
  for_each = { for alert in var.alarms : alert.name => alert }

  name           = "${local.full_name}-${each.value.name}-filter"
  log_group_name = each.value.log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = each.value.metric_namespace
    value     = each.value.metric_value
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each = { for alarm in var.alarms : alarm.name => alarm }

  alarm_name          = "${local.full_name}-${each.value.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = each.value.alarm_threshold
  metric_name         = aws_cloudwatch_log_metric_filter.filter[each.key].metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.filter[each.key].metric_transformation[0].namespace
  period              = each.value.alarm_period
  statistic           = each.value.alarm_statistic
  alarm_description   = each.value.description
  alarm_actions       = length(local.alarm_actions) > 0 ? [aws_sns_topic.topic[each.key].arn] : []
  treat_missing_data  = each.value.treat_missing_data

  tags = local.tags
}

resource "aws_sns_topic" "topic" {
  for_each = local.alarm_actions

  name = "${local.full_name}-${each.value.name}-topic"
  tags = local.tags
}

resource "aws_chatbot_slack_channel_configuration" "slack" {
  for_each = local.alarm_actions

  configuration_name = "${local.full_name}-${each.value.name}-${each.value.slack_channel_id}"
  slack_channel_id   = each.value.slack_channel_id
  slack_team_id      = var.slack_team_id
  sns_topic_arns     = [aws_sns_topic.topic[each.key].arn]
  iam_role_arn       = local.chatbot_role_arn

  tags = local.tags
}
