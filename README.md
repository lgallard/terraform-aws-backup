<!-- BEGIN_TF_DOCS -->
![Terraform](https://lgallardo.com/images/terraform.jpg)

# terraform-aws-backup

Terraform module to create AWS Backup plans. AWS Backup is a fully managed backup service that makes it easy to centralize and automate the back up of data across AWS services (EBS volumes, RDS databases, DynamoDB tables, EFS file systems, and Storage Gateway volumes).

## Features

* Flexible backup plan customization
* Comprehensive backup management:
  - Rules and selections
  - Multiple plans per vault
  - Copy actions and lifecycle policies
  - Retention periods and windows
  - Resource tagging
* Advanced capabilities:
  - IAM role management
  - Multi-region support
  - Vault management
  - Framework integration
  - Organization policies
* Enterprise features:
  - Notifications system
  - Audit Manager integration
  - Cross-account backups
  - Compliance controls

## Usage

You can use this module to create a simple plan using the module's `rule_*` variables. You can also use the `rules` and `selections` list of maps variables to build a more complete plan by defining several rules and selections at once. For multiple backup plans, you can use the `plans` variable to create several plans with their own rules and selections.

Check the [examples](/examples/) folder where you can see how to configure backup plans with different selection criteria.

### Simple plan

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
  min_retention_days = 7  # Minimum retention of 7 days
  max_retention_days = 90 # Maximum retention of 90 days

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
      copy_actions = []
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
      copy_actions = []
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

### Simple plan using variables

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


### Complete plan

```hcl
# AWS SNS Topic
resource "aws_sns_topic" "backup_vault_notifications" {
  name = "backup-vault-events"
}

# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault configuration
  vault_name          = "complete_vault"
  vault_kms_key_arn   = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  vault_force_destroy = true
  min_retention_days  = 7
  max_retention_days  = 360
  locked              = true
  changeable_for_days = 3

  # Backup plan configuration
  plan_name = "complete_backup_plan"

  # Backup rules configuration
  rules = [
    {
      name                     = "rule_1"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      recovery_point_tags = {
        Environment = "prod"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 180
          }
        }
      ]
    },
    {
      name                     = "rule_2"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 360
      }
      recovery_point_tags = {
        Environment = "prod"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 360
          }
        }
      ]
    }
  ]

  # Backup selection configuration
  selections = [
    {
      name = "complete_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "prod"
      }
      resources = [
        "arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
        "arn:aws:ec2:us-west-2:123456789012:volume/vol-12345678"
      ]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "complete_backup"
  }
}
```


### Simple plan using AWS Organizations backup policies

```hcl
module "aws_backup_example" {
  source = "../.."

  # Backup Plan configuration
  plan_name = "organization_backup_plan"

  # Vault configuration
  vault_name         = "organization_backup_vault"
  min_retention_days = 7
  max_retention_days = 365

  rules = [
    {
      name                     = "critical_systems"
      target_vault_name        = "critical_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "high"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 365
          }
        }
      ]
    },
    {
      name                     = "standard_systems"
      target_vault_name        = "standard_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "standard"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 0
            delete_after       = 90
          }
        }
      ]
    }
  ]

  # Selection configuration
  selections = [
    {
      name = "critical_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "high"
      }
    },
    {
      name = "standard_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "standard"
      }
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "organization_backup"
  }
}
```

### Multiple backup plans

```hcl
module "aws_backup_example" {
  source = "lgallard/backup/aws"

  # Vault
  vault_name = "vault-1"

  # Multiple plans
  plans = {
    # First plan for daily backups
    daily = {
      name = "daily-backup-plan"
      rules = [
        {
          name              = "daily-rule"
          schedule          = "cron(0 12 * * ? *)"
          start_window      = 120
          completion_window = 360
          lifecycle = {
            cold_storage_after = 0
            delete_after       = 30
          }
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "daily"
          }
        }
      ]
      selections = {
        prod_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = "prod"
            }
          ]
        }
      }
    },
    # Second plan for weekly backups
    weekly = {
      name = "weekly-backup-plan"
      rules = [
        {
          name              = "weekly-rule"
          schedule          = "cron(0 0 ? * 1 *)" # Run every Sunday at midnight
          start_window      = 120
          completion_window = 480
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 120
          }
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "weekly"
          }
        }
      ]
      selections = {
        all_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1",
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"
          ]
        }
      }
    }
  }

  # Tags
  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }
}
```

### Migrating from Single Plan to Multiple Plans

When upgrading from a previous version that used single plan configuration to the new multiple plans feature, you have two options:

#### Option 1: Continue using single plan (recommended for simple cases)

The module maintains full backward compatibility. Your existing configuration will continue to work without changes:

```hcl
# This will continue to work as before
module "aws_backup_example" {
  source = "lgallard/backup/aws"
  
  vault_name = "my-vault"
  plan_name  = "my-plan"
  
  # Single rule using variables
  rule_name     = "daily-rule"
  rule_schedule = "cron(0 12 * * ? *)"
  
  # Or multiple rules using list
  rules = [
    {
      name     = "rule-1"
      schedule = "cron(0 12 * * ? *)"
      lifecycle = {
        delete_after = 30
      }
    }
  ]
  
  # Single selection using variables
  selection_name = "my-selection"
  selection_resources = ["arn:aws:dynamodb:..."]
  
  # Or multiple selections using list
  selections = [
    {
      name = "selection-1"
      resources = ["arn:aws:dynamodb:..."]
    }
  ]
}
```

#### Option 2: Migrate to multiple plans (recommended for complex scenarios)

If you want to use the new multiple plans feature, follow these steps:

1. **Update your configuration** to use the `plans` variable:

```hcl
# Before: Single plan configuration
module "aws_backup_example" {
  source = "lgallard/backup/aws"
  
  vault_name = "my-vault"
  plan_name  = "my-plan"
  
  rules = [
    {
      name = "daily-rule"
      schedule = "cron(0 12 * * ? *)"
      lifecycle = { delete_after = 30 }
    }
  ]
  
  selections = [
    {
      name = "my-selection"
      resources = ["arn:aws:dynamodb:..."]
    }
  ]
}

# After: Multiple plans configuration
module "aws_backup_example" {
  source = "lgallard/backup/aws"
  
  vault_name = "my-vault"
  
  plans = {
    default = {  # Use "default" as the plan key for smooth migration
      name = "my-plan"
      rules = [
        {
          name = "daily-rule"
          schedule = "cron(0 12 * * ? *)"
          lifecycle = { delete_after = 30 }
        }
      ]
      selections = {
        my-selection = {
          resources = ["arn:aws:dynamodb:..."]
        }
      }
    }
  }
}
```

2. **Handle resource migration** using Terraform state commands:

```bash
# Move the backup plan
terraform state mv 'module.aws_backup_example.aws_backup_plan.ab_plan[0]' 'module.aws_backup_example.aws_backup_plan.ab_plans["default"]'

# Move the backup selection(s) - adjust the selection key as needed
terraform state mv 'module.aws_backup_example.aws_backup_selection.ab_selection[0]' 'module.aws_backup_example.aws_backup_selection.plan_selections["default-my-selection"]'

# If using multiple selections, move each one:
terraform state mv 'module.aws_backup_example.aws_backup_selection.ab_selections["selection-name"]' 'module.aws_backup_example.aws_backup_selection.plan_selections["default-selection-name"]'
```

3. **Run terraform plan** to verify no resources will be recreated:

```bash
terraform plan
# Should show "No changes" if migration was successful
```

> **Note**: The exact state move commands depend on your current configuration. Use `terraform state list` to see your current resource addresses, and `terraform plan` to see what changes would be made before running the state move commands.


### AWS Backup Audit Manager Framework

```hcl
# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Audit Framework
  audit_framework = {
    create      = true
    name        = "exampleFramework"
    description = "this is an example framework"

    controls = [
      # Vault lock check - ensures resources are protected by vault lock
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
        parameter_name  = "maxRetentionDays"
        parameter_value = "100" # Maximum retention period allowed by vault lock
      },
    ]
  }

  # Tags are now specified separately
  tags = {
    Name = "Example Framework"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.91.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_framework.ab_framework](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_framework) | resource |
| [aws_backup_plan.ab_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_report_plan.ab_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_selection.ab_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_selection.ab_selections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.ab_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.ab_vault_lock_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_notifications.backup_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_notifications) | resource |
| [aws_iam_policy.ab_tag_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ab_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ab_backup_s3_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ab_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ab_restores_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ab_restores_s3_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ab_tag_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_organizations_policy.backup_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.backup_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_sns_topic_policy.backup_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_iam_policy_document.ab_role_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ab_tag_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.backup_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_backup_settings"></a> [advanced\_backup\_settings](#input\_advanced\_backup\_settings) | Advanced backup settings by resource type | `map(map(string))` | `{}` | no |
| <a name="input_audit_framework"></a> [audit\_framework](#input\_audit\_framework) | Configuration for AWS Backup Audit Manager framework | <pre>object({<br/>    create      = bool<br/>    name        = string<br/>    description = optional(string)<br/>    controls = list(object({<br/>      name            = string<br/>      parameter_name  = optional(string)<br/>      parameter_value = optional(string)<br/>    }))<br/>  })</pre> | <pre>{<br/>  "controls": [],<br/>  "create": false,<br/>  "description": null,<br/>  "name": null<br/>}</pre> | no |
| <a name="input_backup_policies"></a> [backup\_policies](#input\_backup\_policies) | Map of backup policies to create | <pre>map(object({<br/>    target_vault_name = string<br/>    schedule          = string<br/>    start_window      = number<br/>    completion_window = number<br/>    lifecycle = object({<br/>      delete_after       = number<br/>      cold_storage_after = optional(number)<br/>    })<br/>    recovery_point_tags      = optional(map(string))<br/>    copy_actions             = optional(list(map(string)))<br/>    enable_continuous_backup = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_backup_regions"></a> [backup\_regions](#input\_backup\_regions) | List of regions where backups should be created | `list(string)` | `[]` | no |
| <a name="input_backup_selections"></a> [backup\_selections](#input\_backup\_selections) | Map of backup selections | <pre>map(object({<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    conditions    = optional(map(any))<br/>    tags          = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | The number of days before the lock date. If omitted creates a vault lock in governance mode, otherwise it will create a vault lock in compliance mode | `number` | `null` | no |
| <a name="input_enable_org_policy"></a> [enable\_org\_policy](#input\_enable\_org\_policy) | Enable AWS Organizations backup policy | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Change to false to avoid deploying any AWS Backup resources | `bool` | `true` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | If configured, the module will attach this role to selections, instead of creating IAM resources by itself | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Allow to set IAM role name, otherwise use predefined default | `string` | `""` | no |
| <a name="input_locked"></a> [locked](#input\_locked) | Change to true to add a lock configuration for the backup vault | `bool` | `false` | no |
| <a name="input_max_retention_days"></a> [max\_retention\_days](#input\_max\_retention\_days) | The maximum retention period that the vault retains its recovery points | `number` | `null` | no |
| <a name="input_min_retention_days"></a> [min\_retention\_days](#input\_min\_retention\_days) | The minimum retention period that the vault retains its recovery points | `number` | `null` | no |
| <a name="input_notifications"></a> [notifications](#input\_notifications) | Notification block which defines backup vault events and the SNS Topic ARN to send AWS Backup notifications to. Leave it empty to disable notifications | `any` | `{}` | no |
| <a name="input_notifications_disable_sns_policy"></a> [notifications\_disable\_sns\_policy](#input\_notifications\_disable\_sns\_policy) | Disable the creation of the SNS policy. Enable if you need to manage the policy elsewhere. | `bool` | `false` | no |
| <a name="input_org_policy_description"></a> [org\_policy\_description](#input\_org\_policy\_description) | Description of the AWS Organizations backup policy | `string` | `"AWS Organizations backup policy"` | no |
| <a name="input_org_policy_name"></a> [org\_policy\_name](#input\_org\_policy\_name) | Name of the AWS Organizations backup policy | `string` | `"backup-policy"` | no |
| <a name="input_org_policy_target_id"></a> [org\_policy\_target\_id](#input\_org\_policy\_target\_id) | Target ID (Root/OU/Account) for the backup policy | `string` | `null` | no |
| <a name="input_plan_name"></a> [plan\_name](#input\_plan\_name) | The display name of a backup plan | `string` | `null` | no |
| <a name="input_reports"></a> [reports](#input\_reports) | The default cache behavior for this distribution. | <pre>list(object({<br/>    name               = string<br/>    description        = optional(string, null)<br/>    formats            = optional(list(string), null)<br/>    s3_bucket_name     = string<br/>    s3_key_prefix      = optional(string, null)<br/>    report_template    = string<br/>    accounts           = optional(list(string), null)<br/>    organization_units = optional(list(string), null)<br/>    regions            = optional(list(string), null)<br/>    framework_arns     = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_rule_completion_window"></a> [rule\_completion\_window](#input\_rule\_completion\_window) | The amount of time AWS Backup attempts a backup before canceling the job and returning an error | `number` | `null` | no |
| <a name="input_rule_enable_continuous_backup"></a> [rule\_enable\_continuous\_backup](#input\_rule\_enable\_continuous\_backup) | Enable continuous backups for supported resources. | `bool` | `false` | no |
| <a name="input_rule_lifecycle_cold_storage_after"></a> [rule\_lifecycle\_cold\_storage\_after](#input\_rule\_lifecycle\_cold\_storage\_after) | Specifies the number of days after creation that a recovery point is moved to cold storage | `number` | `null` | no |
| <a name="input_rule_lifecycle_delete_after"></a> [rule\_lifecycle\_delete\_after](#input\_rule\_lifecycle\_delete\_after) | Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after` | `number` | `null` | no |
| <a name="input_rule_name"></a> [rule\_name](#input\_rule\_name) | An display name for a backup rule | `string` | `null` | no |
| <a name="input_rule_recovery_point_tags"></a> [rule\_recovery\_point\_tags](#input\_rule\_recovery\_point\_tags) | Metadata that you can assign to help organize the resources that you create | `map(string)` | `{}` | no |
| <a name="input_rule_schedule"></a> [rule\_schedule](#input\_rule\_schedule) | A CRON expression specifying when AWS Backup initiates a backup job | `string` | `null` | no |
| <a name="input_rule_start_window"></a> [rule\_start\_window](#input\_rule\_start\_window) | The amount of time in minutes before beginning a backup | `number` | `null` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A list of rule maps | <pre>list(object({<br/>    name                     = string<br/>    target_vault_name        = optional(string)<br/>    schedule                 = optional(string)<br/>    start_window             = optional(number)<br/>    completion_window        = optional(number)<br/>    enable_continuous_backup = optional(bool)<br/>    lifecycle = optional(object({<br/>      cold_storage_after = optional(number)<br/>      delete_after       = number<br/>    }))<br/>    recovery_point_tags = optional(map(string))<br/>    copy_actions = optional(list(object({<br/>      destination_vault_arn = string<br/>      lifecycle = optional(object({<br/>        cold_storage_after = optional(number)<br/>        delete_after       = number<br/>      }))<br/>    })))<br/>  }))</pre> | `[]` | no |
| <a name="input_selection_conditions"></a> [selection\_conditions](#input\_selection\_conditions) | A map of conditions that you define to assign resources to your backup plans using tags. | `map(any)` | `{}` | no |
| <a name="input_selection_name"></a> [selection\_name](#input\_selection\_name) | The display name of a resource selection document | `string` | `null` | no |
| <a name="input_selection_not_resources"></a> [selection\_not\_resources](#input\_selection\_not\_resources) | An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to exclude from a backup plan. | `list(any)` | `[]` | no |
| <a name="input_selection_resources"></a> [selection\_resources](#input\_selection\_resources) | An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan | `list(any)` | `[]` | no |
| <a name="input_selection_tags"></a> [selection\_tags](#input\_selection\_tags) | List of tags for `selection_name` var, when using variable definition. | `list(any)` | `[]` | no |
| <a name="input_selections"></a> [selections](#input\_selections) | A list or map of backup selections. If passing a list, each selection must have a name attribute. | `any` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_vault_force_destroy"></a> [vault\_force\_destroy](#input\_vault\_force\_destroy) | A boolean that indicates that all recovery points stored in the vault are deleted so that the vault can be destroyed without error | `bool` | `false` | no |
| <a name="input_vault_kms_key_arn"></a> [vault\_kms\_key\_arn](#input\_vault\_kms\_key\_arn) | The server-side encryption key that is used to protect your backups | `string` | `null` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault to create. If not given, AWS use default | `string` | `null` | no |
| <a name="input_windows_vss_backup"></a> [windows\_vss\_backup](#input\_windows\_vss\_backup) | Enable Windows VSS backup option and create a VSS Windows backup | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_framework_arn"></a> [framework\_arn](#output\_framework\_arn) | The ARN of the backup framework |
| <a name="output_framework_creation_time"></a> [framework\_creation\_time](#output\_framework\_creation\_time) | The date and time that the backup framework was created |
| <a name="output_framework_id"></a> [framework\_id](#output\_framework\_id) | The unique identifier of the backup framework |
| <a name="output_framework_status"></a> [framework\_status](#output\_framework\_status) | The deployment status of the backup framework |
| <a name="output_plan_arn"></a> [plan\_arn](#output\_plan\_arn) | The ARN of the backup plan |
| <a name="output_plan_id"></a> [plan\_id](#output\_plan\_id) | The id of the backup plan |
| <a name="output_plan_role"></a> [plan\_role](#output\_plan\_role) | The service role of the backup plan |
| <a name="output_plan_version"></a> [plan\_version](#output\_plan\_version) | Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the vault |
| <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id) | The name of the vault |
<!-- END_TF_DOCS -->

## Known Issues

During the development of the module, the following issues were found:

### Error creating Backup Vault

In case you get an error message similar to this one:

```
error creating Backup Vault (): AccessDeniedException: status code: 403, request id: 8e7e577e-5b74-4d4d-95d0-bf63e0b2cc2e,
```

Add the [required IAM permissions mentioned in the CreateBackupVault row](https://docs.aws.amazon.com/aws-backup/latest/devguide/access-control.html#backup-api-permissions-ref) to the role or user creating the Vault (the one running Terraform CLI). In particular make sure `kms` and `backup-storage` permissions are added.

## Testing

This module includes comprehensive testing to ensure reliability and prevent regressions.

### Test Types

1. **Validation Tests**: Terraform syntax, formatting, and configuration validation
2. **Security Tests**: Static security analysis using Checkov
3. **Example Tests**: Automated validation of all example configurations
4. **Integration Tests**: Go-based tests using Terratest for actual AWS resource testing

### Running Tests Locally

#### Prerequisites

- Terraform >= 1.0.0
- Go >= 1.21 (for integration tests)
- Python 3.11+ (for security scanning)
- AWS credentials configured (for integration tests)

#### Quick Test Commands

```bash
# Install dependencies
make install-deps

# Run all validation and security tests (no AWS resources created)
make test

# Run format and validate
make validate

# Run security scanning
make security

# Validate all examples
make validate-examples

# Run integration tests (requires AWS credentials)
make test-integration

# Run all tests including integration
make test-all
```

#### Manual Testing

```bash
# Basic validation
terraform init
terraform validate
terraform fmt -check -recursive

# Security scan
checkov -d . --framework terraform --quiet

# Test examples
cd examples/simple_plan
terraform init && terraform validate

# Run Go tests
cd test
go test -v ./...
```

### CI/CD Pipeline

The module uses GitHub Actions for automated testing:

- **Matrix Testing**: Tests against multiple Terraform versions (1.0, 1.5, 1.6) and AWS provider versions (4.0, 5.0, 5.30)
- **Example Validation**: All examples are automatically validated
- **Security Scanning**: Checkov runs on every push and pull request
- **Integration Tests**: Run on labeled PRs or pushes to main branches

### Test Structure

```
test/
├── terraform_basic_test.go       # Basic validation tests
├── terraform_aws_backup_test.go  # Comprehensive backup functionality tests
└── ...                          # Additional test files
```

### Writing Tests

When contributing new features:

1. Add validation tests for new configurations
2. Update integration tests for new AWS resources
3. Add example configurations and ensure they pass validation
4. Update documentation

<!-- END_TF_DOCS -->