data "aws_iam_policy_document" "backup_events" {
  count = local.enable_notifications ? 1 : 0
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
      var.sns_topici_arn
    ]
    sid = "BackupPublishEvents"
  }
}

resource "aws_sns_topic_policy" "backup_events" {
  count  = local.enable_notifications ? 1 : 0
  arn    = var.sns_topic_arn
  policy = data.aws_iam_policy_document.backup_events.json
}

resource "aws_backup_vault_notifications" "backup_events" {
  count               = local.enable_notifications ? 1 : 0
  backup_vault_name   = var.vault_name != null ? var.vault_name : "Default"
  sns_topic_arn       = var.sns_topic_arn
  backup_vault_events = var.notifications_backup_vault_events
}

locals {
  # Whether to enable notifications or not
  enable_notifications = var.enabled && length(var.notifications_backup_vault_events) > 0 ? true : false
}
