# Before migration - legacy single plan configuration
module "aws_backup_before" {
  source = "../.."

  # Vault
  vault_name = "my-backup-vault"

  # Single plan using rules list
  plan_name = "daily-backup-plan"
  rules = [
    {
      name     = "daily-rule"
      schedule = "cron(0 12 * * ? *)"
      lifecycle = {
        delete_after = 30
      }
    }
  ]

  # Multiple selections
  selections = [
    {
      name = "production-dbs"
      resources = [
        "arn:aws:dynamodb:us-east-1:123456789012:table/prod-table1",
        "arn:aws:rds:us-east-1:123456789012:db:prod-db1"
      ]
    },
    {
      name = "development-dbs"
      resources = [
        "arn:aws:dynamodb:us-east-1:123456789012:table/dev-table1"
      ]
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}