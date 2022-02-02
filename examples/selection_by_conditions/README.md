# Selection by Conditions

This example shows you how to define selection using conditions, without `resource` definitions.

## Selection by Tags vs. Conditions

**Conditions**

Selection by conditions differs from selection by tags as follows: When you specify more than one condition, you only assign the resources that match **ALL conditions** (using `AND` logic).  Selection by conditions supports `StringEquals`, `StringLike`, `StringNotEquals`, and `StringNotLike`. Selection by tags only supports `StringEquals`.

**Tags**
Selection by tags differs from selection by conditions as follows: When you specify more than one condition, you assign all resources that match **AT LEAST ONE condition** (using `OR` logic).  Selection by tags only supports `StringEquals`. Conditions supports `StringEquals`, `StringLike`, `StringNotEquals`, and `StringNotLike`.

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
      schedule            = "cron(0 7 * * ? *)"
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
  #  - Selection-1: By tags: Environment = prod, Owner = devops
  selections = [
    {
      name      = "selection-1"
      conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/Component"
            value = "rds"
          }
          ,
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
    Environment = "prod"
    Terraform   = true
  }

}
```
