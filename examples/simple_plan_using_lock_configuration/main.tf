module "aws_backup_example" {

  source = "../.."

  # Vault
  vault_name = "vault-4"

  # Vault lock configuration
  locked              = true
  min_retention_days  = 7
  max_retention_days  = 360
  changeable_for_days = 3

  # Plan
  plan_name = "locked-backup-plan"

  # Rules
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      copy_actions = [] # Initialize as empty list
      recovery_point_tags = {
        Environment = "prod"
      }
    },
    {
      name              = "rule-2"
      target_vault_name = "Default"
      schedule          = "cron(0 7 * * ? *)"
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 360
      }
      copy_actions = [] # Initialize as empty list
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Selection
  selections = [
    {
      name = "selection-1"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        }
      ]
    }
  ]

  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }

}
