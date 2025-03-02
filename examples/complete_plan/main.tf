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
  plan_name = "complete-plan"

  # Notifications
  notifications = {
    sns_topic_arn       = aws_sns_topic.backup_vault_notifications.arn
    backup_vault_events = ["BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED", "BACKUP_JOB_FAILED", "RESTORE_JOB_COMPLETED"]
  }

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
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Multiple selections
  #  - Selection-1: By resources and tags
  #  - Selection-2: Only by resources
  #  - Selection-3: By resources and conditions
  selections = [
    {
      name          = "selection-1"
      resources     = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"]
      not_resources = []
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "production"
        },
        {
          type  = "STRINGEQUALS"
          key   = "Owner"
          value = "production"
        }
      ]
    },
    {
      name      = "selection-2"
      resources = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"]
    },
    {
      name          = "selection-3"
      resources     = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table3"]
      not_resources = []
      conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/Component"
            value = "rds"
          },
          {
            key   = "aws:ResourceTag/Project"
            value = "Project1"
          }
        ]
        string_like = [
          {
            key   = "aws:ResourceTag/Application"
            value = "app*"
          }
        ]
        string_not_equals = [
          {
            key   = "aws:ResourceTag/Backup"
            value = "false"
          }
        ]
        string_not_like = [
          {
            key   = "aws:ResourceTag/Environment"
            value = "test*"
          }
        ]
      }
    }
  ]

  tags = {
    Owner       = "devops"
    Environment = "production"
    Terraform   = true
  }
}
