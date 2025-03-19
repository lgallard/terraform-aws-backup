# Windows VSS Backup Example

This example demonstrates the Windows VSS (Volume Shadow Copy Service) backup functionality of the AWS Backup module. Windows VSS is a feature that allows for consistent backups of Windows EC2 instances.

## Usage

To run this example, execute:

```bash
terraform init
terraform plan
terraform apply
```

## Testing the Validation Logic

This example includes proper configuration with EC2 instances in the selection, which is required when Windows VSS backup is enabled.

### Testing the Error Case

To test the error case (when Windows VSS is enabled but no EC2 instances are selected), modify the `main.tf` file:

1. Comment out the current `selection_resources` block
2. Uncomment the error test case below
3. Run `terraform plan`

```terraform
  # Comment out the current selection_resources
  /*
  selection_resources = [
    "arn:aws:ec2:us-west-2:123456789012:instance/i-1234567890abcdef0",
    "arn:aws:dynamodb:us-west-2:123456789012:table/my-table"
  ]
  */

  # Uncomment this to test the error case
  selection_resources = [
    # No EC2 instances here - will trigger the validation error
    "arn:aws:dynamodb:us-west-2:123456789012:table/my-table"
  ]
```

You should see an error message:

```
Error: Resource precondition failed

  on .terraform/modules/backup/main.tf line XX, in resource "aws_backup_plan" "ab_plan":
   XX:     condition     = !var.windows_vss_backup || (length(local.selection_resources) > 0 && can(regex(".*EC2.*", join(",", local.selection_resources))))
     ├────────────────
     │ local.selection_resources doesn't contain EC2 instances
     │ var.windows_vss_backup is true

  Windows VSS backup is enabled but no EC2 instances are selected for backup. Either disable windows_vss_backup or include EC2 instances in your backup selection.
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Notes

- Windows VSS backup is only applicable to Windows EC2 instances
- When enabled, at least one EC2 instance must be included in the backup selection
- This can be done via direct ARN references or tag-based selection 