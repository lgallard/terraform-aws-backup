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
