#  Notifications only on failed jobs

This is an example snippet based on the support article that explains how to do it in the AWS console

[How can I get notifications for AWS Backup jobs that failed?](https://aws.amazon.com/es/premiumsupport/knowledge-center/aws-backup-failed-job-notification/)



```hcl
module "backup" {
  source = "lgallard/backup/aws"

  [...]

  # Only notify on failed jobs.
  # https://aws.amazon.com/es/premiumsupport/knowledge-center/aws-backup-failed-job-notification/
  notifications = {
    sns_topic_arn = aws_sns_topic.backup_vault_notifications.arn,
    backup_vault_events = ["BACKUP_JOB_COMPLETED"]
  }
}

resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup_notifications"
}

resource "aws_sns_topic_subscription" "devops_subscription" {
  endpoint = var.backup_notification_address
  protocol = "email-json"
  topic_arn = aws_sns_topic.backup_vault_notifications.arn
  filter_policy = jsonencode(
    {
      "State" = [
        {
          "anything-but" = "COMPLETED"
        }
      ]
    }
  )
}
```

Thanks @iainelder for this example!
