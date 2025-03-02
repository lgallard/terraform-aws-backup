# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-3"

  # Vault lock configuration
  min_retention_days = 7  # Minimum retention of 7 days
  max_retention_days = 90 # Maximum retention of 90 days

  # Plan
  plan_name = "simple-plan"

  # Multiple rules using a list of maps
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
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

  # Multiple selections
  selections = [
    {
      name = "selection-1"
      resources = [
        "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1",
        "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"
      ]
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
