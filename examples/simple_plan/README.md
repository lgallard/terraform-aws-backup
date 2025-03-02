<!-- BEGIN_TF_DOCS -->
# Simple Plan Example

This example shows how to create a simple AWS Backup plan with:
- A backup vault named "vault-3"
- A backup plan with two rules:
  - Rule 1: Daily backup at 12 PM UTC with 90-day retention
  - Rule 2: Daily backup at 7 AM UTC with 90-day retention
- Resource selection based on both tags and resource ARNs
- Recovery point tags for environment tracking

## Usage

```hcl
# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-3"

  # Vault lock configuration
  min_retention_days = 7    # Minimum retention of 7 days
  max_retention_days = 90   # Maximum retention of 90 days

  # Plan
  plan_name = "simple-plan"

  # Multiple rules using a list of maps
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
      copy_actions        = []
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
      copy_actions        = []
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Multiple selections
  selections = [
    {
      name = "selection-1"
      resources = [
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

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.89.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_backup_example"></a> [aws\_backup\_example](#module\_aws\_backup\_example) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.backup_vault_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment configuration map. Used to define environment-specific parameters like tags, resource names, and other settings | `map(any)` | <pre>{<br/>  "Environment": "prod",<br/>  "Owner": "devops",<br/>  "Terraform": true<br/>}</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS -->
