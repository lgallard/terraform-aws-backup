module "aws_backup_conditions" {
  source = "../../../.."

  # Basic configuration
  plan_name  = "conditions-backup-plan"
  vault_name = "conditions-backup-vault"

  rules = [
    {
      name              = "conditions-backup-rule"
      target_vault_name = "conditions-backup-vault"
      schedule          = "cron(0 5 ? * * *)"
      start_window      = 480
      completion_window = 600
      lifecycle = {
        delete_after = 30
      }
    }
  ]

  # Test the conditions functionality
  selections = {
    conditions_test = {
      conditions = {
        string_equals = {
          "aws:ResourceTag/Environment"   = "dev"
          "aws:ResourceTag/BackupEnabled" = "true"
        }
        string_not_equals = {
          "aws:ResourceTag/SkipBackup" = "true"
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    TestCase    = "conditions"
  }
}