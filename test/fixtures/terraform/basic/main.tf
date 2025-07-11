module "backup" {
  source = "../../../../"

  plan_name      = var.plan_name
  vault_name     = var.vault_name
  selection_name = var.selection_name

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
    name      = var.selection_name
    resources = ["*"]
  }]

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}