# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-2"

  # Plan
  plan_name = "selection-by-tags-plan"

  # Multiple rules using a list of maps
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
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
        cold_storage_after = 0
        delete_after       = 90
      }
      copy_actions = []
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Multiple selections with tags
  selections = [
    {
      name = "selection-1"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        },
        {
          type  = "STRINGEQUALS"
          key   = "Owner"
          value = "devops"
        }
      ]
    },
    {
      name = "selection-2"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Application"
          value = "web"
        },
        {
          type  = "STRINGEQUALS"
          key   = "Tier"
          value = "frontend"
        }
      ]
    }
  ]

  tags = {
    Owner       = "devops"
    Environment = "production"
    Terraform   = true
  }
}
