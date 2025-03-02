<!-- BEGIN_TF_DOCS -->
# AWS Backup - Selection by Tags Example

Configuration in this directory creates an AWS Backup plan that selects resources based on specific tags and includes an SNS topic for notifications.

## Features

This example demonstrates how to:
- Select AWS resources for backup using tags
- Create a backup vault with retention policies
- Configure a backup plan with specific schedule and lifecycle rules
- Set up notifications for backup events

## Tag-Based Selection

Resources are selected for backup when they have both:
- `Environment = "prod"` tag
- `Backup = "true"` tag

This provides a simple opt-in mechanism where resources can be tagged for inclusion in the backup plan.

## Backup Schedule

The backup plan is configured with:
- Daily backups at 5 AM (cron(0 5 ? * * *))
- 8-hour start window (480 minutes)
- 9.35-hour completion window (561 minutes)

## Lifecycle Management

Backups follow this lifecycle:
- Move to cold storage after 30 days
- Delete after 180 days
- Minimum retention of 7 days
- Maximum retention of 365 days

## Notifications

An SNS topic named "backup-vault-events" is created to:
- Monitor backup job status
- Track backup vault events
- Enable automated response to backup events

## Example Usage

```hcl
# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Backup Plan configuration
  plan_name = "selection_by_tags_plan"

  # Vault configuration
  vault_name = "selection_by_tags_vault"
  min_retention_days = 7
  max_retention_days = 365

  rules = [
    {
      name                     = "rule_1"
      target_vault_name       = "selection_by_tags_vault"
      schedule                = "cron(0 5 ? * * *)"
      start_window            = 480
      completion_window       = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      recovery_point_tags = {
        Environment = "prod"
        Service    = "backup"
      }
      copy_actions = []
    }
  ]

  # Selection configuration using tags
  selections = [
    {
      name = "selection_by_tags"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        },
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "true"
        }
      ]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "selection_by_tags"
  }
}
```

## Recovery Point Tags

Each backup (recovery point) is tagged with:
- Environment = "prod"
- Service = "backup"

These tags help with backup management and cost allocation.
<!-- END_TF_DOCS -->
