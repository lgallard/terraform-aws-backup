# AWS Backup Global Settings Example

This example demonstrates how to configure AWS Backup global settings for centralized cross-account backup governance.

## Features Demonstrated

- **Global Settings Management**: Enable and configure AWS Backup global settings
- **Cross-Account Backup**: Enable centralized backup governance across multiple AWS accounts
- **Enterprise Governance**: Account-level settings for backup operations
- **Backup Configuration**: Basic vault, plan, and selection setup with global settings

## Architecture

```
AWS Account (Management/Central)
├── Global Settings (Account-level)
│   └── isCrossAccountBackupEnabled: true
├── Backup Vault
├── Backup Plan
└── Resource Selections
```

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example will create resources which may cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_backup_global_settings"></a> [aws\_backup\_global\_settings](#module\_aws\_backup\_global\_settings) | ../.. | n/a |

## Resources

Created by the module:
- `aws_backup_global_settings` - Account-level backup settings
- `aws_backup_vault` - Backup vault for storing recovery points
- `aws_backup_plan` - Backup plan with scheduling and lifecycle policies
- `aws_backup_selection` - Resource selection for automated backups

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Number of days to retain backups | `number` | `30` | no |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | Cron expression for backup schedule | `string` | `"cron(0 2 * * ? *)"` | no |
| <a name="input_enable_cross_account_backup"></a> [enable\_cross\_account\_backup](#input\_enable\_cross\_account\_backup) | Enable cross-account backup functionality | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to resources | `map(string)` | `{"BackupGovernance": "centralized", "Environment": "production", "Owner": "backup-team", "Terraform": true}` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault to create | `string` | `"centralized-backup-vault"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cross_account_backup_enabled"></a> [cross\_account\_backup\_enabled](#output\_cross\_account\_backup\_enabled) | Whether cross-account backup is enabled |
| <a name="output_global_settings"></a> [global\_settings](#output\_global\_settings) | Configured global settings |
| <a name="output_global_settings_id"></a> [global\_settings\_id](#output\_global\_settings\_id) | AWS Account ID where global settings are applied |
| <a name="output_global_settings_summary"></a> [global\_settings\_summary](#output\_global\_settings\_summary) | Summary of global settings configuration |
| <a name="output_plan_arn"></a> [plan\_arn](#output\_plan\_arn) | ARN of the backup plan |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | ARN of the backup vault |

## Global Settings Configuration

### Cross-Account Backup Enablement

When `isCrossAccountBackupEnabled` is set to `"true"`:

1. **Centralized Governance**: Enables centralized backup management across AWS accounts
2. **Organization Policies**: Allows AWS Organizations backup policies to be applied
3. **Cross-Account IAM**: Enables backup operations across account boundaries
4. **Compliance**: Supports enterprise compliance frameworks requiring centralized backup

### Enterprise Use Cases

- **Multi-Account Organizations**: Centralized backup governance for AWS Organizations
- **Compliance Requirements**: Meeting regulatory requirements for backup management
- **Security**: Controlled cross-account backup operations
- **Cost Optimization**: Centralized backup strategies and policies

## Next Steps

After deploying this example:

1. **Configure AWS Organizations Backup Policies** for centralized governance
2. **Set up cross-account IAM roles** for backup operations
3. **Implement backup compliance frameworks** across accounts
4. **Monitor backup activities** through AWS CloudTrail and CloudWatch

## Important Notes

- Global settings are **account-level** configurations (one per AWS account)
- Cross-account backup requires proper **IAM permissions** across accounts
- This feature is particularly valuable for **enterprise environments**
- Consider **AWS Organizations integration** for complete centralized governance

## Compliance and Security

This configuration supports:
- SOC 2 compliance for backup governance
- GDPR requirements for data retention
- HIPAA backup and recovery standards
- Financial services backup regulations