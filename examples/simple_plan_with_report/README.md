# Simple plan with report

This example shows you how to create a simple plan and a backup report:

```
module "aws_backup_example" {

  source = "lgallard/backup/aws"

  # Vault
  vault_name = "vault-1"

  # Plan
  plan_name = "simple-plan-list"

  # One rule using a list of maps
  rules = [
    {
      name                     = "rule-1"
      schedule                 = "cron(0 12 * * ? *)"
      start_window             = 120
      completion_window        = 360
      enable_continuous_backup = true
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      },
      recovery_point_tags = {
        Environment = "production"
      }
    },
  ]

  # One selection using a list of maps
  selections = [
    {
      name      = "selection-1"
      resources = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table"]
    },
  ]

  reports = [
    {
      name            = "report-vault-1"
      formats         = ["CSV"]
      s3_bucket_name  = "my-backup-reports""
      s3_key_prefix   = "vault-1/"
      report_template = "BACKUP_JOB_REPORT"
    }
  ]

  tags = {
    Owner       = "devops"
    Environment = "production"
    Terraform   = true
  }

}
```
