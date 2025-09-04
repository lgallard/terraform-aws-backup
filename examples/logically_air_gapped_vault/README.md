# AWS Backup - Logically Air Gapped Vault

This example shows how to create an AWS Backup plan with a **logically air gapped vault** for enhanced security and compliance requirements.

## Features

- **Logically Air Gapped Vault**: Enhanced isolation for backup data
- **Mandatory Retention Policies**: Built-in retention enforcement (7-year retention for compliance)
- **Compliance Ready**: Designed for SOX, PCI-DSS, HIPAA, and other regulatory requirements
- **Daily Backup Schedule**: Automated daily backups at 1 AM
- **Multi-Service Support**: Backs up DynamoDB tables, EBS volumes, and RDS databases

## Key Differences from Standard Vault

| Feature | Standard Vault | Logically Air Gapped Vault |
|---------|-----------------|---------------------------|
| **Encryption** | Optional KMS encryption | AWS-managed encryption (always on) |
| **Retention** | Optional vault lock | **Mandatory** min/max retention days |
| **Use Case** | General backup storage | High-security, compliance environments |
| **Recovery** | Standard recovery process | Enhanced security controls |

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example creates resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.11.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.11.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_backup_plan"></a> [aws\_backup\_plan](#module\_aws\_backup\_plan) | ../../ | n/a |

## Configuration

The example demonstrates a compliance-focused backup configuration:

- **Vault Type**: `logically_air_gapped`
- **Retention**: 7 days minimum, 2555 days (7 years) maximum
- **Schedule**: Daily backups at 1:00 AM UTC
- **Resources**: DynamoDB tables, EBS volumes, and RDS databases

## Compliance Benefits

### Enhanced Security
- Logically isolated from standard backup infrastructure
- Built-in retention enforcement prevents accidental deletion
- Enhanced audit trail for compliance reporting

### Regulatory Compliance
- **SOX (Sarbanes-Oxley)**: Long-term retention of financial data
- **PCI-DSS**: Secure backup of payment processing systems
- **HIPAA**: Protected health information backup requirements
- **General Data Protection**: Write-once-read-many (WORM) characteristics

## Example Terraform Configuration

```hcl
module "compliance_backup" {
  source = "lgallard/backup/aws"

  # Air Gapped Vault Configuration
  vault_name         = "compliance-air-gapped-vault"
  vault_type         = "logically_air_gapped"
  min_retention_days = 7     # AWS minimum for flexibility
  max_retention_days = 2555  # 7 years for compliance

  # Backup Plan
  plan_name     = "compliance-backup-plan"
  rule_name     = "daily-backup-rule"
  rule_schedule = "cron(0 1 ? * * *)"  # Daily at 1 AM

  # Resource Selection
  selection_name = "critical-systems"
  selection_resources = [
    "arn:aws:dynamodb:*:*:table/*",
    "arn:aws:ec2:*:*:volume/*",
    "arn:aws:rds:*:*:db:*"
  ]

  tags = {
    Environment = "production"
    Purpose     = "compliance"
    Compliance  = "SOX"
    Owner       = "data-governance-team"
  }
}
```

## Important Notes

1. **Retention Requirements**: Air gapped vaults **require** both `min_retention_days` and `max_retention_days` to be specified
2. **AWS Provider Version**: Requires AWS provider version >= 6.11.0 for air gapped vault support
3. **Cost Implications**: Air gapped vaults may have different pricing than standard vaults
4. **Recovery Process**: Recovery from air gapped vaults follows enhanced security procedures

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vault_id"></a> [vault\_id](#output\_vault\_id) | The name of the air gapped vault |
| <a name="output_vault_arn"></a> [vault\_arn](#output\_vault\_arn) | The ARN of the air gapped vault |
| <a name="output_vault_type"></a> [vault\_type](#output\_vault\_type) | The type of vault created |
| <a name="output_airgapped_vault_recovery_points"></a> [airgapped\_vault\_recovery\_points](#output\_airgapped\_vault\_recovery\_points) | The number of recovery points stored in the air gapped vault |
| <a name="output_plan_id"></a> [plan\_id](#output\_plan\_id) | The id of the backup plan |
| <a name="output_plan_arn"></a> [plan\_arn](#output\_plan\_arn) | The ARN of the backup plan |

## Security Considerations

- Air gapped vaults provide enhanced isolation but cannot use custom KMS keys
- Retention policies are immutable once set
- Access patterns are logged for compliance auditing
- Recovery operations require additional authentication steps