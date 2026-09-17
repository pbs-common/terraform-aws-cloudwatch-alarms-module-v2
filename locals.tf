locals {
  name      = var.name != null ? var.name : var.product
  full_name = "${local.name}-${var.environment}"

  chatbot_role_arn = var.chatbot_role_arn != null ? var.chatbot_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/amazonq-slack-chat-role"

  default_tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      "${var.organization}:billing:owner"       = var.owner
      creator                                   = "terraform"
      repo                                      = var.repo
    }
  )
  tags = merge({ for k, v in local.default_tags : k => v if lookup(data.aws_default_tags.common_tags.tags, k, "") != v })

  alarms = { for alarm in var.alarms : alarm.name => alarm }

  # Alarms that derive their metric from a log group. AWS-published metric alarms need no filter.
  log_metric_alarms = { for alarm in var.alarms : alarm.name => alarm if alarm.log_group_name != null }

  alarm_actions = { for alarm in var.alarms : alarm.name => alarm if alarm.slack_channel_id != "" }
  slack_channels = {
    for alarm in values(local.alarm_actions) : alarm.slack_channel_id => alarm...
  }

  # Resource names. A caller-supplied alarm_name/filter_name is used verbatim so alarms that
  # already exist under another name can be adopted rather than recreated.
  alarm_names = {
    for alarm in var.alarms :
    alarm.name => alarm.alarm_name != null ? alarm.alarm_name : "${local.full_name}-${alarm.name}-alarm"
  }

  filter_names = {
    for alarm in local.log_metric_alarms :
    alarm.name => alarm.filter_name != null ? alarm.filter_name : "${local.full_name}-${alarm.name}-filter"
  }

  # ARN of the SNS topic this module created for an alarm, keyed by alarm name. Empty for alarms
  # without a slack_channel_id.
  created_topic_arns = { for name, topic in aws_sns_topic.topic : name => topic.arn }

  # Existing targets the caller passed, plus the topic this module created for that alarm.
  effective_alarm_actions = {
    for alarm in var.alarms :
    alarm.name => distinct(concat(
      coalesce(alarm.alarm_actions, []),
      [for topic_name, arn in local.created_topic_arns : arn if topic_name == alarm.name],
    ))
  }

  # Explicit only: a module-created topic delivers alarm notifications, not recoveries.
  effective_ok_actions = {
    for alarm in var.alarms : alarm.name => coalesce(alarm.ok_actions, [])
  }
}

data "aws_default_tags" "common_tags" {}
