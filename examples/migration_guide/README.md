# Migration Example: Single Plan to Multiple Plans

This example demonstrates how to migrate from the legacy single plan configuration to the new multiple plans feature.

## Before Migration (Legacy Configuration)

```hcl
module "aws_backup_example" {
  source = "lgallard/backup/aws"
  
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
```

## After Migration (Multiple Plans Configuration)

```hcl
module "aws_backup_example" {
  source = "lgallard/backup/aws"
  
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
```

## Migration Steps

1. **Check current resources**:
```bash
terraform state list | grep aws_backup
```
Expected output:
```
module.aws_backup_example.aws_backup_plan.ab_plan[0]
module.aws_backup_example.aws_backup_selection.ab_selections["production-dbs"]
module.aws_backup_example.aws_backup_selection.ab_selections["development-dbs"]
```

2. **Update configuration** to use the `plans` variable (as shown above)

3. **Move resources in Terraform state**:
```bash
# Move the backup plan
terraform state mv \
  'module.aws_backup_example.aws_backup_plan.ab_plan[0]' \
  'module.aws_backup_example.aws_backup_plan.ab_plans["default"]'

# Move backup selections
terraform state mv \
  'module.aws_backup_example.aws_backup_selection.ab_selections["production-dbs"]' \
  'module.aws_backup_example.aws_backup_selection.plan_selections["default-production-dbs"]'

terraform state mv \
  'module.aws_backup_example.aws_backup_selection.ab_selections["development-dbs"]' \
  'module.aws_backup_example.aws_backup_selection.plan_selections["default-development-dbs"]'
```

4. **Verify migration**:
```bash
terraform plan
```
Should show "No changes" if migration was successful.

## Notes

- Use "default" as the plan key to follow the migration pattern
- Selection keys in the new structure follow the pattern: `"{plan_key}-{selection_key}"`
- The plan name and all other configuration can remain the same
- After successful migration, you can rename the plan key if desired (requires additional state moves)

## Extending After Migration

Once migrated, you can easily add additional plans:

```hcl
plans = {
  default = {
    # Your existing daily backup plan
    name = "daily-backup-plan"
    rules = [/* existing rules */]
    selections = {/* existing selections */}
  }
  
  # Add a new weekly backup plan
  weekly = {
    name = "weekly-backup-plan"
    rules = [
      {
        name     = "weekly-rule"
        schedule = "cron(0 0 ? * 1 *)"  # Every Sunday
        lifecycle = {
          delete_after = 90
        }
      }
    ]
    selections = {
      critical-systems = {
        resources = [
          "arn:aws:rds:us-east-1:123456789012:db:critical-db"
        ]
      }
    }
  }
}
```