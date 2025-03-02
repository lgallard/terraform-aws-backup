<!-- BEGIN_TF_DOCS -->
# Simple Plan Using Variables Example

This example demonstrates how to create an AWS Backup plan using the module's variables. It shows:
- Direct usage of module variables without creating additional variable definitions
- A backup vault with lock configuration (7-120 days retention)
- A single backup rule with:
  - Daily backup at 12 PM UTC
  - 30 days cold storage
  - 120 days retention
- Resource selection combining:
  - Direct resource ARNs (DynamoDB tables)
  - Tag-based selection (Environment = prod)
- Proper tagging for backup resources and recovery points

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
```

Note: This example demonstrates the module's variable inputs. In a real-world scenario, you might want to:
- Define your own variables
- Use data sources for resource ARNs
- Adjust retention periods based on your requirements
- Customize tag values for your environment

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
| <a name="input_max_retention_days"></a> [max\_retention\_days](#input\_max\_retention\_days) | Maximum retention period in days for the vault lock configuration | `number` | `120` | no |
| <a name="input_min_retention_days"></a> [min\_retention\_days](#input\_min\_retention\_days) | Minimum retention period in days for the vault lock configuration | `number` | `7` | no |
| <a name="input_plan_name"></a> [plan\_name](#input\_plan\_name) | Name of the backup plan | `string` | `"simple-plan"` | no |
| <a name="input_rule_completion_window"></a> [rule\_completion\_window](#input\_rule\_completion\_window) | The amount of time in minutes AWS Backup attempts a backup before canceling the job | `number` | `360` | no |
| <a name="input_rule_lifecycle_cold_storage_after"></a> [rule\_lifecycle\_cold\_storage\_after](#input\_rule\_lifecycle\_cold\_storage\_after) | Specifies the number of days after creation that a recovery point is moved to cold storage | `number` | `30` | no |
| <a name="input_rule_lifecycle_delete_after"></a> [rule\_lifecycle\_delete\_after](#input\_rule\_lifecycle\_delete\_after) | Specifies the number of days after creation that a recovery point is deleted | `number` | `120` | no |
| <a name="input_rule_name"></a> [rule\_name](#input\_rule\_name) | Name of the backup rule | `string` | `"rule-1"` | no |
| <a name="input_rule_recovery_point_tags"></a> [rule\_recovery\_point\_tags](#input\_rule\_recovery\_point\_tags) | Tags to assign to the backup recovery point | `map(string)` | <pre>{<br/>  "Environment": "prod"<br/>}</pre> | no |
| <a name="input_rule_schedule"></a> [rule\_schedule](#input\_rule\_schedule) | A CRON expression specifying when AWS Backup initiates a backup job | `string` | `"cron(0 12 * * ? *)"` | no |
| <a name="input_rule_start_window"></a> [rule\_start\_window](#input\_rule\_start\_window) | The amount of time in minutes before beginning a backup | `number` | `120` | no |
| <a name="input_selection_name"></a> [selection\_name](#input\_selection\_name) | Name of the backup selection | `string` | `"selection-1"` | no |
| <a name="input_selection_resources"></a> [selection\_resources](#input\_selection\_resources) | List of ARNs of resources to backup | `list(string)` | <pre>[<br/>  "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1",<br/>  "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"<br/>]</pre> | no |
| <a name="input_selection_tags"></a> [selection\_tags](#input\_selection\_tags) | List of tag conditions used to filter resources for backup | <pre>list(object({<br/>    type  = string<br/>    key   = string<br/>    value = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "key": "Environment",<br/>    "type": "STRINGEQUALS",<br/>    "value": "prod"<br/>  }<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to assign to the backup resources | `map(string)` | <pre>{<br/>  "Environment": "prod",<br/>  "Owner": "backup team",<br/>  "Terraform": true<br/>}</pre> | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault to create | `string` | `"vault-1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- END_TF_DOCS -->
