# Selection by tags 

This example shows you how to define selection using tags, without `resource` definitions:

```
module "aws_backup_example" {

  source = "lgallard/backup/aws"

  # Vault
  vault_name = "vault-4"

  # Plan
  plan_name = "selection-tags-plan"

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
      },
      recovery_point_tags = {
        Environment = "prod"
      }
    },
    {
      name                = "rule-2"
      target_vault_name   = "Default"
      schedule            = null
      start_window        = 120
      completion_window   = 360
      lifecycle           = {}
      copy_action         = {}
      recovery_point_tags = {}
    },
  ]

  # Multiple selections
  #  - Selection-1: Environment = prod
  #  - Selection-2: Backup = critical
  selections = [
    {
      name = "selection-1"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "prod"
      }
    },
    {
      name = "selection-2"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Backup"
        value = "critial"
      }
    },
  ]

  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }

}
```

