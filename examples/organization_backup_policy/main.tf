module "aws_backup_example" {
  source = "../.."

  # Backup Plan configuration
  plan_name = "organization_backup_plan"

  # Vault configuration
  vault_name         = "organization_backup_vault"
  min_retention_days = 7
  max_retention_days = 365

  rules = [
    {
      name                     = "critical_systems"
      target_vault_name        = "critical_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "high"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 365
          }
        }
      ]
    },
    {
      name                     = "standard_systems"
      target_vault_name        = "standard_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "standard"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 0
            delete_after       = 90
          }
        }
      ]
    }
  ]

  # Selection configuration
  selections = [
    {
      name = "critical_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "high"
      }
    },
    {
      name = "standard_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "standard"
      }
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "organization_backup"
  }
}
