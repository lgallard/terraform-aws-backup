module "backup" {
  source = "../../../../"

  # Multiple backup plans
  plans = [
    {
      name = "daily-backup-plan"
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
    },
    {
      name = "weekly-backup-plan"
      rules = [{
        name              = "weekly_backup"
        schedule          = "cron(0 2 ? * 1 *)"
        target_vault_name = var.vault_name
        start_window      = 60
        completion_window = 240
        lifecycle = {
          cold_storage_after = 30
          delete_after       = 2555
        }
      }]
    }
  ]

  vault_name = var.vault_name

  tags = {
    Environment = "test"
    Purpose     = "terratest-multiple"
  }
}