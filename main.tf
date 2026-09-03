resource "aws_cloudwatch_log_metric_filter" "filter" {
  for_each = local.log_metric_alarms

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
  for_each = local.alarms

  alarm_name          = "${local.full_name}-${each.value.name}-alarm"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.alarm_threshold
  metric_name         = each.value.metric_name
  namespace           = each.value.metric_namespace
  dimensions          = each.value.dimensions
  period              = each.value.alarm_period
  statistic           = each.value.alarm_statistic
  extended_statistic  = each.value.extended_statistic
  alarm_description   = each.value.description
  alarm_actions       = contains(keys(local.alarm_actions), each.key) ? [aws_sns_topic.topic[each.key].arn] : []
  treat_missing_data  = each.value.treat_missing_data

  tags = local.tags

  # The metric is referenced by name, so create the filter that publishes it first.
  depends_on = [aws_cloudwatch_log_metric_filter.filter]
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
