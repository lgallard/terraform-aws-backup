# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault configuration
  vault_name          = "complete_vault"
  vault_kms_key_arn   = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  vault_force_destroy = true
  min_retention_days  = 7
  max_retention_days  = 360
  locked              = true
  changeable_for_days = 3

  # Backup plan configuration
  plan_name = "complete_backup_plan"

  # Backup rules configuration
  rules = [
    {
      name                     = "rule_1"
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
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 180
          }
        }
      ]
    },
    {
      name                     = "rule_2"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 360
      }
      recovery_point_tags = {
        Environment = "prod"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 360
          }
        }
      ]
    }
  ]

  # Backup selection configuration
  selections = [
    {
      name = "complete_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "prod"
      }
      resources = [
        "arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
        "arn:aws:ec2:us-west-2:123456789012:volume/vol-12345678"
      ]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "complete_backup"
  }
}
