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

  alarm_actions = { for alarm in var.alarms : alarm.name => alarm if alarm.slack_channel_id != "" }
}

data "aws_default_tags" "common_tags" {}
