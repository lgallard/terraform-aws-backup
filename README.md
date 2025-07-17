<!-- BEGIN_TF_DOCS -->
![Terraform](https://lgallardo.com/images/terraform.jpg)

# terraform-aws-backup

Terraform module to create AWS Backup plans. AWS Backup is a fully managed backup service that makes it easy to centralize and automate the back up of data across AWS services (EBS volumes, RDS databases, DynamoDB tables, EFS file systems, and Storage Gateway volumes).

## Features

* Flexible backup plan customization
* Comprehensive backup management:
  - Rules and selections
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
        delete_after = 90
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
        delete_after = 90
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

### Multiple backup plans

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
            delete_after = 30
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
    },
    # Third plan for monthly backups with cross-region copy
    monthly = {
      name = "monthly-backup-plan"
      rules = [
        {
          name              = "monthly-rule"
          schedule          = "cron(0 0 1 * ? *)" # Run at midnight on the first day of every month
          start_window      = 120
          completion_window = 720
          lifecycle = {
            cold_storage_after = 90
            delete_after       = 365
          }
          copy_actions = [
            {
              destination_vault_arn = "arn:aws:backup:us-west-2:123456789101:backup-vault:Default"
              lifecycle = {
                cold_storage_after = 90
                delete_after       = 365
              }
            }
          ]
          recovery_point_tags = {
            Environment = "prod"
            Frequency   = "monthly"
          }
        }
      ]
      selections = {
        critical_databases = {
          resources = [
            "arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Criticality"
              value = "high"
            }
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
        delete_after = 90
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "standard"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            delete_after = 90
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

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
| [aws_backup_plan.ab_plans](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_report_plan.ab_report](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_selection.ab_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_selection.ab_selections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_selection.plan_selections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.ab_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.ab_vault_lock_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_notifications.backup_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_notifications) | resource |
| [aws_iam_policy.ab_tag_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ab_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ab_managed_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
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
| <a name="input_backup_selections"></a> [backup\_selections](#input\_backup\_selections) | Map of backup selections | <pre>map(object({<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    conditions = optional(object({<br/>      string_equals     = optional(map(string))<br/>      string_not_equals = optional(map(string))<br/>      string_like       = optional(map(string))<br/>      string_not_like   = optional(map(string))<br/>    }))<br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | The number of days before the lock date. If omitted creates a vault lock in governance mode, otherwise it will create a vault lock in compliance mode | `number` | `null` | no |
| <a name="input_default_lifecycle_cold_storage_after_days"></a> [default\_lifecycle\_cold\_storage\_after\_days](#input\_default\_lifecycle\_cold\_storage\_after\_days) | Default number of days after creation that a recovery point is moved to cold storage. Used when cold\_storage\_after is not specified in lifecycle configuration. | `number` | `0` | no |
| <a name="input_default_lifecycle_delete_after_days"></a> [default\_lifecycle\_delete\_after\_days](#input\_default\_lifecycle\_delete\_after\_days) | Default number of days after creation that a recovery point is deleted. Used when delete\_after is not specified in lifecycle configuration. | `number` | `90` | no |
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
| <a name="input_plans"></a> [plans](#input\_plans) | A map of backup plans to create. Each key is the plan name and each value is a map of plan configuration. | <pre>map(object({<br/>    name = optional(string)<br/>    rules = list(object({<br/>      name                     = string<br/>      target_vault_name        = optional(string)<br/>      schedule                 = optional(string)<br/>      start_window             = optional(number)<br/>      completion_window        = optional(number)<br/>      enable_continuous_backup = optional(bool)<br/>      lifecycle = optional(object({<br/>        cold_storage_after = optional(number)<br/>        delete_after       = number<br/>      }))<br/>      recovery_point_tags = optional(map(string))<br/>      copy_actions = optional(list(object({<br/>        destination_vault_arn = string<br/>        lifecycle = optional(object({<br/>          cold_storage_after = optional(number)<br/>          delete_after       = number<br/>        }))<br/>      })), [])<br/>    }))<br/>    selections = optional(map(object({<br/>      resources     = optional(list(string))<br/>      not_resources = optional(list(string))<br/>      conditions = optional(object({<br/>        string_equals     = optional(map(string))<br/>        string_not_equals = optional(map(string))<br/>        string_like       = optional(map(string))<br/>        string_not_like   = optional(map(string))<br/>      }))<br/>      selection_tags = optional(list(object({<br/>        type  = string<br/>        key   = string<br/>        value = string<br/>      })))<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_reports"></a> [reports](#input\_reports) | The default cache behavior for this distribution. | <pre>list(object({<br/>    name               = string<br/>    description        = optional(string, null)<br/>    formats            = optional(list(string), null)<br/>    s3_bucket_name     = string<br/>    s3_key_prefix      = optional(string, null)<br/>    report_template    = string<br/>    accounts           = optional(list(string), null)<br/>    organization_units = optional(list(string), null)<br/>    regions            = optional(list(string), null)<br/>    framework_arns     = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_rule_completion_window"></a> [rule\_completion\_window](#input\_rule\_completion\_window) | The amount of time AWS Backup attempts a backup before canceling the job and returning an error | `number` | `null` | no |
| <a name="input_rule_enable_continuous_backup"></a> [rule\_enable\_continuous\_backup](#input\_rule\_enable\_continuous\_backup) | Enable continuous backups for supported resources. | `bool` | `false` | no |
| <a name="input_rule_lifecycle_cold_storage_after"></a> [rule\_lifecycle\_cold\_storage\_after](#input\_rule\_lifecycle\_cold\_storage\_after) | Specifies the number of days after creation that a recovery point is moved to cold storage | `number` | `null` | no |
| <a name="input_rule_lifecycle_delete_after"></a> [rule\_lifecycle\_delete\_after](#input\_rule\_lifecycle\_delete\_after) | Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after` | `number` | `null` | no |
| <a name="input_rule_name"></a> [rule\_name](#input\_rule\_name) | An display name for a backup rule | `string` | `null` | no |
| <a name="input_rule_recovery_point_tags"></a> [rule\_recovery\_point\_tags](#input\_rule\_recovery\_point\_tags) | Metadata that you can assign to help organize the resources that you create | `map(string)` | `{}` | no |
| <a name="input_rule_schedule"></a> [rule\_schedule](#input\_rule\_schedule) | A CRON expression specifying when AWS Backup initiates a backup job | `string` | `null` | no |
| <a name="input_rule_start_window"></a> [rule\_start\_window](#input\_rule\_start\_window) | The amount of time in minutes before beginning a backup | `number` | `null` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A list of rule maps | <pre>list(object({<br/>    name                     = string<br/>    target_vault_name        = optional(string)<br/>    schedule                 = optional(string)<br/>    start_window             = optional(number)<br/>    completion_window        = optional(number)<br/>    enable_continuous_backup = optional(bool)<br/>    lifecycle = optional(object({<br/>      cold_storage_after = optional(number)<br/>      delete_after       = number<br/>    }))<br/>    recovery_point_tags = optional(map(string))<br/>    copy_actions = optional(list(object({<br/>      destination_vault_arn = string<br/>      lifecycle = optional(object({<br/>        cold_storage_after = optional(number)<br/>        delete_after       = number<br/>      }))<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_selection_conditions"></a> [selection\_conditions](#input\_selection\_conditions) | A map of conditions that you define to assign resources to your backup plans using tags. | <pre>object({<br/>    string_equals     = optional(map(string))<br/>    string_not_equals = optional(map(string))<br/>    string_like       = optional(map(string))<br/>    string_not_like   = optional(map(string))<br/>  })</pre> | `{}` | no |
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
| <a name="output_plans"></a> [plans](#output\_plans) | Map of plans created and their attributes |
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
<!-- END_TF_DOCS -->

## Testing

This module includes comprehensive testing to ensure reliability and prevent regressions.

### Test Structure

- **Validation Tests**: Terraform format, syntax, and basic validation across multiple Terraform and AWS provider versions
- **Security Scanning**: Static analysis using `checkov` and `tfsec` to identify security issues
- **Example Tests**: Automated validation of all example configurations
- **Integration Tests**: Real AWS resource creation/destruction testing using Terratest

### Running Tests Locally

#### Prerequisites

1. Install Go 1.21+
2. Install Terraform 1.0+
3. Configure AWS credentials

#### Example Validation Tests

```bash
cd test
go test -v -timeout 10m -run TestExamples
```

#### Integration Tests (requires AWS credentials)

```bash
cd test
go test -v -timeout 30m -run TestBasicBackupPlan
go test -v -timeout 30m -run TestIAMRoleCreation
```

#### Security Scanning

```bash
# Install tools
pip install checkov
curl -L https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64 -o tfsec
chmod +x tfsec && sudo mv tfsec /usr/local/bin/

# Run scans
checkov -d . --framework terraform
tfsec .
```

### CI/CD Workflows

The module includes automated testing through GitHub Actions:

- **Validate Workflow**: Runs on every push/PR - Terraform validation and format checking
- **Security Workflow**: Runs on every push/PR and weekly - Security scanning with checkov/tfsec
- **Test Workflow**: Manual trigger and weekly schedule - Comprehensive integration testing

### Test Coverage

The test suite covers:

- ✅ Basic backup plan creation
- ✅ Multiple backup plans
- ✅ Cross-region backup scenarios
- ✅ IAM role and policy validation
- ✅ Backup vault configuration
- ✅ Notification integration
- ✅ All example configurations
- ✅ Security best practices
- ✅ Multi-version compatibility (Terraform 1.0+, AWS Provider 4.0+)

### Contributing

When contributing to this module:

1. Ensure all tests pass: `cd test && go test -v ./...`
2. Run security scans: `checkov -d . && tfsec .`
3. Update examples if adding new features
4. Add integration tests for new functionality

## Troubleshooting

### Common Issues

If you encounter issues with the module, check these common problems:

1. **AccessDeniedException**: Ensure your IAM user/role has the necessary permissions for AWS Backup operations
2. **InvalidParameterValueException**: Check that schedule expressions, lifecycle values, and ARNs are properly formatted
3. **Backup Job Failures**: Verify resource permissions and backup windows are sufficient
4. **Cross-Region Issues**: Ensure both regions support cross-region backups and KMS key permissions are configured

### Getting Help

For detailed troubleshooting steps:

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Comprehensive troubleshooting guide with step-by-step solutions
- **[KNOWN_ISSUES.md](KNOWN_ISSUES.md)** - Known issues and workarounds
- **[BEST_PRACTICES.md](BEST_PRACTICES.md)** - Best practices and optimization tips
- **[PERFORMANCE.md](PERFORMANCE.md)** - Performance tuning guide

### Quick Debug Steps

1. **Enable Debug Logging**:
   ```bash
   export TF_LOG=DEBUG
   export TF_LOG_PATH=terraform.log
   terraform plan
   ```

2. **Check AWS Service Health**: Verify AWS Backup is available in your region

3. **Validate Configuration**:
   ```bash
   terraform validate
   terraform plan
   ```

4. **Check Resource State**:
   ```bash
   aws backup list-backup-vaults
   aws backup list-backup-plans
   ```

## Known Issues

During the development of the module, the following issues were found:

### Error creating Backup Vault

In case you get an error message similar to this one:

```
error creating Backup Vault (): AccessDeniedException: status code: 403, request id: 8e7e577e-5b74-4d4d-95d0-bf63e0b2cc2e,
```

Add the [required IAM permissions mentioned in the CreateBackupVault row](https://docs.aws.amazon.com/aws-backup/latest/devguide/access-control.html#backup-api-permissions-ref) to the role or user creating the Vault (the one running Terraform CLI). In particular make sure `kms` and `backup-storage` permissions are added.