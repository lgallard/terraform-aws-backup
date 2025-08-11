resource "aws_sns_topic" "backup_notifications" {
  name = var.topic_name
}

module "backup" {
  source = "../../../../"

  plan_name             = var.plan_name
  vault_name            = var.vault_name
  selection_name = "test-backup-selection"

  # Basic backup rule
  rules = [{
    name              = "daily_backup"
    schedule          = "cron(0 2 ? * * *)"
    target_vault_name = var.vault_name
    start_window      = 60
    completion_window = 120
    lifecycle = {
      cold_storage_after = 30
      delete_after       = 365
    }
  }]

  # Basic backup selection
  selections = [{
    name      = "test-backup-selection"
    resources = ["*"]
  }]

  # Notifications
  notifications = {
    sns_topic_arn = aws_sns_topic.backup_notifications.arn
    backup_vault_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED"
    ]
  }

  tags = {
    Environment = "test"
    Purpose     = "terratest-notifications"
  }
}
