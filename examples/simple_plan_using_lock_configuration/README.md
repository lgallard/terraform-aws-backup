<!-- BEGIN_TF_DOCS -->
# Simple Plan Using Lock Configuration Example

This example demonstrates how to create an AWS Backup plan with vault locking enabled. It shows:
- A backup vault with lock configuration:
  - Minimum retention of 7 days
  - Maximum retention of 360 days
  - 3 days window to make changes to the lock configuration
- Two backup rules with different retention periods:
  - Rule 1: Daily backup at 12 PM UTC, 180 days retention, 30 days cold storage
  - Rule 2: Daily backup at 7 AM UTC, 360 days retention, 30 days cold storage
- Tag-based resource selection (Environment = prod)
- Proper tagging for backup resources and recovery points

## Important Notes

When using vault locking:
- Once locked, a vault's retention settings cannot be decreased
- The changeable_for_days period starts when the lock is first enabled
- After the changeable period, the lock becomes immutable
- Ensure your retention periods comply with the vault's min/max settings

## Usage

```hcl
module "aws_backup_example" {

  source = "../.."

  # Vault
  vault_name = "vault-4"

  # Vault lock configuration
  locked              = true
  min_retention_days  = 7
  max_retention_days  = 360
  changeable_for_days = 3

  # Plan
  plan_name = "locked-backup-plan"

  # Rules
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      copy_actions        = []  # Initialize as empty list
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
        cold_storage_after = 30
        delete_after       = 360
      }
      copy_actions        = []  # Initialize as empty list
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Selection
  selections = [
    {
      name = "selection-1"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        }
      ]
    }
  ]

  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }

}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.26 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_backup_example"></a> [aws\_backup\_example](#module\_aws\_backup\_example) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment configuration map. Used to define environment-specific parameters like tags, resource names, and other settings | `map(any)` | <pre>{<br/>  "Environment": "prod",<br/>  "Owner": "devops",<br/>  "Terraform": true<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS -->
