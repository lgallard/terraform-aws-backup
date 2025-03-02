# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-1"

  # Vault lock configuration
  min_retention_days = 7
  max_retention_days = 120

  # Plan
  plan_name = "simple-plan"

  # Rule
  rule_name                         = "rule-1"
  rule_schedule                     = "cron(0 12 * * ? *)"
  rule_start_window                 = 120
  rule_completion_window            = 360
  rule_lifecycle_cold_storage_after = 30
  rule_lifecycle_delete_after       = 120
  rule_recovery_point_tags = {
    Environment = "prod"
  }

  # Selection
  selection_name = "selection-1"
  selection_resources = [
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

  # Tags
  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }
}
