# AWS Backup Global Settings Example
# 
# This example demonstrates how to configure AWS Backup global settings
# for centralized cross-account backup governance.

# AWS Backup with Global Settings
module "aws_backup_global_settings" {
  source = "../.."

  # Enable global settings management
  enable_global_settings = true

  # Configure global settings for cross-account backup governance
  global_settings = {
    "isCrossAccountBackupEnabled" = "true"
  }

  # Basic vault configuration
  vault_name = "centralized-backup-vault"

  # Basic plan for demonstration
  plan_name = "global-settings-plan"

  # Simple rule
  rules = [
    {
      name              = "daily-backup"
      schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM
      start_window      = 120
      completion_window = 360
      lifecycle = {
        delete_after = 30
      }
      copy_actions = []
      recovery_point_tags = {
        BackupType  = "Automated"
        Governance  = "Centralized"
        Environment = "production"
      }
    }
  ]

  # Resource selection
  selections = [
    {
      name = "production-resources"
      resources = [
        "arn:aws:ec2:*:*:instance/*",
        "arn:aws:rds:*:*:db:*"
      ]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "production"
        },
        {
          type  = "STRINGEQUALS"
          key   = "BackupRequired"
          value = "true"
        }
      ]
    }
  ]

  tags = {
    Owner            = "backup-team"
    Environment      = "production"
    BackupGovernance = "centralized"
    Terraform        = true
  }
}