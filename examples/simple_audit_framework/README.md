# Simple AWS Backup Audit Framework Example

This example demonstrates how to create a basic AWS Backup Audit Framework configuration using this Terraform module.

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
- Basic AWS Backup Audit Framework setup
- Configuration of common backup controls
- Setting retention period requirements
- Encryption requirements for EBS volumes

## Audit Controls Explained

The example includes three essential controls:

1. `BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN`
   - Ensures resources are protected by a backup plan
   - Requires minimum 30-day retention

2. `BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK`
   - Verifies recovery points meet minimum retention period
   - Set to 30 days in this example

3. `BACKUP_RECOVERY_POINT_ENCRYPTED`
   - Ensures EBS volume backups are encrypted
   - Specifically targets EBS resources

## Notes

- This is a basic example intended for testing and learning
- For production use, consider the complete example with additional security controls
- Remember to replace placeholder values with your actual AWS resource identifiers
