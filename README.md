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

See [examples/simple_plan/main.tf](examples/simple_plan/main.tf) for a basic backup plan configuration.

### Simple plan using variables

See [examples/simple_plan_using_variables/main.tf](examples/simple_plan_using_variables/main.tf) for a backup plan using variables.

### Complete plan

See [examples/complete_plan/main.tf](examples/complete_plan/main.tf) for a comprehensive backup plan setup.

### Multiple backup plans

See [examples/multiple_plans/main.tf](examples/multiple_plans/main.tf) for managing multiple backup plans.

### Simple plan using AWS Organizations backup policies

See [examples/organization_backup_policy/main.tf](examples/organization_backup_policy/main.tf) for organization-wide backup policies.

### AWS Backup Audit Manager Framework

See [examples/simple_audit_framework/main.tf](examples/simple_audit_framework/main.tf) for audit framework configuration.

### Logically Air Gapped Vault

This module supports AWS Backup Logically Air Gapped Vaults for enhanced security and compliance requirements. Air-gapped vaults provide isolated storage with immutable retention policies.

See [examples/logically_air_gapped_vault/main.tf](examples/logically_air_gapped_vault/main.tf) for air-gapped vault configuration.

**Key Features:**
- **Enhanced Security**: Logical isolation from standard backup infrastructure
- **Immutable Retention**: Mandatory min/max retention policies that cannot be bypassed
- **Compliance Ready**: Supports SOX, PCI-DSS, HIPAA, and other regulatory requirements
- **AWS-Managed Encryption**: Built-in encryption (custom KMS keys not supported)

**Usage:**
```hcl
module "compliance_backup" {
  source = "lgallard/backup/aws"

  vault_name         = "compliance-vault"
  vault_type         = "logically_air_gapped"
  min_retention_days = 7
  max_retention_days = 2555  # 7 years for compliance

  # ... other configuration
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_framework.ab_framework](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_framework) | resource |
| [aws_backup_logically_air_gapped_vault.ab_airgapped_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_logically_air_gapped_vault) | resource |
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
| <a name="input_max_retention_days"></a> [max\_retention\_days](#input\_max\_retention\_days) | The maximum retention period that the vault retains its recovery points. Required when vault\_type is 'logically\_air\_gapped' | `number` | `null` | no |
| <a name="input_min_retention_days"></a> [min\_retention\_days](#input\_min\_retention\_days) | The minimum retention period that the vault retains its recovery points. Required when vault\_type is 'logically\_air\_gapped' | `number` | `null` | no |
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
| <a name="input_vault_type"></a> [vault\_type](#input\_vault\_type) | Type of backup vault to create. Valid values are 'standard' (default) or 'logically\_air\_gapped' | `string` | `"standard"` | no |
| <a name="input_windows_vss_backup"></a> [windows\_vss\_backup](#input\_windows\_vss\_backup) | Enable Windows VSS backup option and create a VSS Windows backup | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_airgapped_vault_arn"></a> [airgapped\_vault\_arn](#output\_airgapped\_vault\_arn) | The ARN of the air gapped vault |
| <a name="output_airgapped_vault_id"></a> [airgapped\_vault\_id](#output\_airgapped\_vault\_id) | The name of the air gapped vault |
| <a name="output_airgapped_vault_recovery_points"></a> [airgapped\_vault\_recovery\_points](#output\_airgapped\_vault\_recovery\_points) | The number of recovery points stored in the air gapped vault (sensitive for security) |
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
| <a name="output_vault_type"></a> [vault\_type](#output\_vault\_type) | The type of vault created |
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

## Known Issues

During the development of the module, the following issues were found:

### Error creating Backup Vault

In case you get an error message similar to this one:

```
error creating Backup Vault (): AccessDeniedException: status code: 403, request id: 8e7e577e-5b74-4d4d-95d0-bf63e0b2cc2e,
```

Add the [required IAM permissions mentioned in the CreateBackupVault row](https://docs.aws.amazon.com/aws-backup/latest/devguide/access-control.html#backup-api-permissions-ref) to the role or user creating the Vault (the one running Terraform CLI). In particular make sure `kms` and `backup-storage` permissions are added.
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

## Known Issues

During the development of the module, the following issues were found:

### Error creating Backup Vault

In case you get an error message similar to this one:

```
error creating Backup Vault (): AccessDeniedException: status code: 403, request id: 8e7e577e-5b74-4d4d-95d0-bf63e0b2cc2e,
```

Add the [required IAM permissions mentioned in the CreateBackupVault row](https://docs.aws.amazon.com/aws-backup/latest/devguide/access-control.html#backup-api-permissions-ref) to the role or user creating the Vault (the one running Terraform CLI). In particular make sure `kms` and `backup-storage` permissions are added.
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

## Automation & Feature Discovery

### Automated Feature Discovery System

This module includes an automated feature discovery system that runs weekly to identify new AWS Backup features, deprecations, and bug fixes from the AWS provider. The system uses Claude Code with MCP (Model Context Protocol) servers to analyze provider documentation and automatically create GitHub issues for new functionality.

#### How It Works

1. **Weekly Scanning**: Every Sunday at 00:00 UTC, the system scans the latest AWS provider documentation
2. **MCP Integration**: Uses Terraform and Context7 MCP servers to access up-to-date provider docs
3. **Intelligent Analysis**: Compares provider capabilities with current module implementation
4. **Automated Issues**: Creates categorized GitHub issues for discovered items:
   - 🚀 **New Features** - Backup resources/arguments not yet implemented
   - ⚠️ **Deprecations** - Features being phased out requiring action
   - 🐛 **Bug Fixes** - Important provider fixes affecting the module

#### Feature Discovery Workflow

The discovery process follows this workflow:

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│                 │    │                      │    │                     │
│  Weekly Trigger │───▶│   Claude Code CLI    │───▶│   GitHub Issues     │
│  (GitHub Action)│    │   + MCP Servers      │    │   (Auto-created)    │
│                 │    │                      │    │                     │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
                                 │
                                 ▼
                       ┌──────────────────────┐
                       │                      │
                       │  Feature Tracking    │
                       │    Database          │
                       │  (.github/tracker/)  │
                       │                      │
                       └──────────────────────┘
```

#### Manual Discovery

You can manually trigger feature discovery:

```bash
# Standard discovery
gh workflow run feature-discovery.yml

# Dry run mode (analyze without creating issues)
gh workflow run feature-discovery.yml -f dry_run=true

# Specific provider version
gh workflow run feature-discovery.yml -f provider_version=5.82.0

# Force full scan
gh workflow run feature-discovery.yml -f force_scan=true
```

#### Discovery Categories

The system identifies and categorizes findings as:

**New Features (`enhancement` label):**
- New Backup resources (`aws_backup_*`)
- New arguments on existing resources
- New data sources (`data.aws_backup_*`)
- New compliance and audit capabilities
- New cross-region and disaster recovery features
- New cost optimization and lifecycle management
- New organization-wide backup governance
- New VSS and Windows integration features

**Deprecations (`deprecation` label):**
- Arguments marked for removal
- Resources being phased out
- Backup patterns no longer recommended
- Configuration approaches outdated

**Bug Fixes (`bug` label):**
- Provider fixes affecting module functionality
- Data protection and security patches
- Performance and reliability improvements

#### Issue Templates

Each discovery type uses a structured template:

- **New Features**: Implementation checklist, examples, testing requirements
- **Deprecations**: Migration guidance, timeline, impact assessment
- **Bug Fixes**: Impact analysis, testing strategy, version requirements

#### Feature Tracking

All discoveries are tracked in `.github/feature-tracker/backup-features.json`:

```json
{
  "metadata": {
    "last_scan": "2025-01-21T00:00:00Z",
    "provider_version": "5.82.0",
    "scan_count": 42
  },
  "current_implementation": {
    "resources": {
      "aws_backup_vault": {
        "implemented": ["name", "kms_key_arn", "force_destroy"],
        "pending": ["backup_vault_lock_configuration"]
      }
    }
  },
  "discovered_features": {
    "new_resources": {},
    "deprecations": {},
    "bug_fixes": {}
  }
}
```

#### MCP Server Integration

The system leverages Model Context Protocol servers for real-time documentation access:

- **Terraform MCP**: `@modelcontextprotocol/server-terraform@latest`
  - AWS provider resource documentation
  - Argument specifications and examples
  - Version compatibility information

- **Context7 MCP**: `@upstash/context7-mcp@latest`
  - Provider changelogs and release notes
  - Community discussions and best practices
  - Historical change tracking

#### Benefits

- **Stay Current**: Never miss new AWS Backup features
- **Proactive Maintenance**: Identify deprecations before they break
- **Automated Tracking**: Comprehensive feature database
- **Community Value**: Users benefit from latest AWS capabilities
- **Reduced Manual Work**: No need for manual provider monitoring

#### Contributing to Discovery

The system is designed to minimize false positives, but you can help improve accuracy:

1. **Review Auto-Created Issues**: Validate and prioritize discoveries
2. **Update Tracking**: Mark features as implemented when complete
3. **Improve Templates**: Suggest enhancements to issue templates
4. **Report Gaps**: Let us know if the system misses important features

For more details on the discovery system architecture, see `.github/scripts/discovery-prompt.md`.
