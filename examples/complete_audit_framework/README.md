# Complete AWS Backup Audit Framework Example

This example demonstrates a comprehensive AWS Backup Audit Framework configuration with organization-wide policy assignment, reporting, and notifications.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0.0 |

## Features Demonstrated

This example demonstrates:
- Comprehensive AWS Backup Audit Framework setup
- Organization-wide policy assignment
- Multi-region backup compliance
- Backup reporting configuration
- SNS notifications for backup events
- KMS encryption for backup vault
- Multiple audit controls with various parameters

## Audit Controls Explained

The example includes five comprehensive controls:

1. `BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN`
   - Ensures resources are protected by a backup plan
   - Requires minimum 35-day retention

2. `BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK`
   - Verifies recovery points meet minimum retention period
   - Set to 35 days in this example

3. `BACKUP_RECOVERY_POINT_ENCRYPTED`
   - Ensures all resource type backups are encrypted
   - Applies to all supported resource types

4. `BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN`
   - Specific check for RDS resources
   - Ensures RDS databases are included in backup plans

5. `BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK`
   - Validates backup frequency
   - Configured for hourly checks

## Organization-wide Policy

The example configures organization-wide backup policies:
- Applies to multiple AWS regions
- Targets specific organizational units
- Implements opt-in preference for new accounts

## Reporting Configuration

Demonstrates comprehensive backup reporting:
- Multiple output formats (CSV, JSON)
- Custom S3 bucket destination
- Multi-account coverage
- Multi-region reporting
- Daily compliance reporting

## Important Notes

Before applying this example:

1. Replace these placeholder values with your actual values:
   - KMS key ARN
   - AWS Account IDs
   - Organization Unit IDs
   - S3 bucket name
   - Backup policy ID

2. Ensure you have:
   - Appropriate IAM permissions
   - AWS Organizations setup (if using organization features)
   - S3 bucket created for reports
   - KMS key with proper permissions

3. Consider costs associated with:
   - AWS Backup storage
   - Cross-region backup copies
   - S3 storage for reports
   - SNS message delivery
