locals {
    # Whether to enable notifications or not
    enable_notifications = var.enabled && length(var.notifications_backup_vault_events) > 0 ? true : false
}

resource "aws_sns_topic" "backup_events" {
  count  = local.enable_notifications ? 1 : 0
  name = var.notifications_sns_topic_name
}

data "aws_iam_policy_document" "backup_events" {
  statement {
    actions = [
      "SNS:Publish",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    resources = [
      local.enable_notifications ? aws_sns_topic.backup_events[0].arn : "",
    ]
    sid = "BackupPublishEvents"
  }
}

resource "aws_sns_topic_policy" "backup_events" {
  count  = local.enable_notifications ? 1 : 0
  arn    = aws_sns_topic.backup_events[0].arn
  policy = data.aws_iam_policy_document.backup_events.json
}

resource "aws_backup_vault_notifications" "backup_events" {
  count               = local.enable_notifications ? 1 : 0
  backup_vault_name   = var.vault_name != null ? var.vault_name : "Default"
  sns_topic_arn       = aws_sns_topic.backup_events[0].arn
  backup_vault_events = var.notifications_backup_vault_events
}

resource "aws_sns_topic_subscription" "backup_events" {
  for_each = var.notifications_topic_subscriptions

  topic_arn              = aws_sns_topic.backup_events[0].arn
  protocol               = var.notifications_topic_subscriptions[each.key].protocol
  endpoint               = var.notifications_topic_subscriptions[each.key].endpoint
  endpoint_auto_confirms = var.notifications_topic_subscriptions[each.key].endpoint_auto_confirms
}
