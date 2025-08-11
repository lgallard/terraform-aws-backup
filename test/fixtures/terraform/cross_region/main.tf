provider "aws" {
  alias  = "source"
  region = var.source_region
}

provider "aws" {
  alias  = "destination"
  region = var.destination_region
}

# Source region backup
module "backup_source" {
  source = "../../../../"

  providers = {
    aws = aws.source
  }

  plan_name             = var.plan_name
  vault_name            = var.vault_name
  selection_name = "cross-region-backup-selection"

  # Basic backup rule with cross-region copy
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
    copy_actions = [{
      destination_vault_arn = module.backup_destination.backup_vault_arn
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
    }]
  }]

  # Basic backup selection
  selections = [{
    name      = "cross-region-backup-selection"
    resources = ["*"]
  }]

  tags = {
    Environment = "test"
    Purpose     = "terratest-cross-region"
  }
}

# Destination region backup vault
module "backup_destination" {
  source = "../../../../"

  providers = {
    aws = aws.destination
  }

  vault_name = var.vault_name

  # Only create vault, no plans
  plans = []

  tags = {
    Environment = "test"
    Purpose     = "terratest-cross-region-dest"
  }
}
