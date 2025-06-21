# Test DynamoDB table for integration testing
resource "aws_dynamodb_table" "test_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = "test"
    Purpose     = "integration-testing"
    Terraform   = "true"
  }
}

# AWS Backup module configuration
module "aws_backup" {
  source = "../../.."

  # Vault configuration
  vault_name = var.vault_name

  # Plan configuration
  plan_name = var.plan_name

  # Backup rules
  rules = [
    {
      name              = "daily-backup"
      schedule          = "cron(0 12 * * ? *)"
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 7
      }
      copy_actions = []
      recovery_point_tags = {
        Environment = "test"
        Purpose     = "integration-testing"
      }
    }
  ]

  # Backup selections - include the test DynamoDB table
  selections = [
    {
      name = "test-dynamodb-selection"
      resources = [
        aws_dynamodb_table.test_table.arn
      ]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "test"
        }
      ]
    }
  ]

  tags = {
    Environment = "test"
    Purpose     = "integration-testing"
    Terraform   = "true"
  }
}