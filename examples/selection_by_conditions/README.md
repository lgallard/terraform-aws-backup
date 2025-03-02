<!-- BEGIN_TF_DOCS -->
# AWS Backup - Selection by Conditions Example

Configuration in this directory creates AWS Backup plan with selections based on tag conditions and an SNS topic for notifications.

## Features

This example showcases the following features:

- Tag-based resource selection using STRINGEQUALS conditions
- Backup vault with retention policies
- Daily backup schedule with lifecycle rules
- SNS topic for backup notifications
- Resource tagging strategy

## Selection Strategy

Resources are selected for backup based on tag matching:
- Environment tag must equal "prod"
- Service tag must equal "web"

This allows for precise targeting of resources that need to be backed up.

## Backup Configuration

The backup plan includes:
- Daily backups at 5 AM
- 30-day transition to cold storage
- 180-day retention period
- 8-hour start window
- 9.35-hour completion window

## Vault Settings

The backup vault is configured with:
- Minimum retention: 7 days
- Maximum retention: 365 days

## Notifications

An SNS topic is created for backup vault notifications:
- Topic name: backup-vault-events
- Enables monitoring of backup events and status

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
  plan_name = "selection_by_conditions_plan"

  # Vault configuration
  vault_name         = "selection_by_conditions_vault"
  min_retention_days = 7
  max_retention_days = 365

  rules = [
    {
      name                     = "rule_1"
      target_vault_name        = "selection_by_conditions_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      recovery_point_tags = {
        Environment = "prod"
        Service     = "backup"
      }
      copy_actions = []
    }
  ]

  # Selection configuration using conditions
  selections = [
    {
      name = "selection_by_conditions"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        },
        {
          type  = "STRINGEQUALS"
          key   = "Service"
          value = "web"
        }
      ]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "selection_by_conditions"
  }
}
```

## Notes

- Only STRINGEQUALS is supported for tag conditions
- Multiple tags can be combined for more precise resource selection
- Recovery points are tagged with Environment and Service tags
- Cross-region copies are not enabled in this example
<!-- END_TF_DOCS -->
