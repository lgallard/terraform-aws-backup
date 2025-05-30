# After migration - multiple plans configuration
module "aws_backup_example" {
  source = "../.."
  
  # Vault (unchanged)
  vault_name = "my-backup-vault"
  
  # Multiple plans configuration
  plans = {
    default = {
      name = "daily-backup-plan"  # Keep the same plan name
      rules = [
        {
          name     = "daily-rule"
          schedule = "cron(0 12 * * ? *)"
          lifecycle = {
            delete_after = 30
          }
        }
      ]
      selections = {
        production-dbs = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789012:table/prod-table1",
            "arn:aws:rds:us-east-1:123456789012:db:prod-db1"
          ]
        }
        development-dbs = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789012:table/dev-table1"
          ]
        }
      }
    }
  }
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Example of extending with additional plans after migration
# plans = {
#   default = {
#     # Your existing daily backup plan (as above)
#   }
#   
#   weekly = {
#     name = "weekly-backup-plan"
#     rules = [
#       {
#         name     = "weekly-rule"
#         schedule = "cron(0 0 ? * 1 *)"  # Every Sunday
#         lifecycle = {
#           delete_after = 90
#         }
#       }
#     ]
#     selections = {
#       critical-systems = {
#         resources = [
#           "arn:aws:rds:us-east-1:123456789012:db:critical-db"
#         ]
#       }
#     }
#   }
# }