# AWS Backup Data Sources

This document provides guidance on using AWS Backup data sources with this Terraform module.

## Overview

AWS Backup data sources allow you to query existing backup resources created by AWS Backup. These data sources are useful for:

- Referencing backup configurations managed outside this module
- Querying information about existing backup selections
- Building integrations with external backup infrastructure
- Compliance and auditing workflows

## Available Data Sources

### aws_backup_selection

The `aws_backup_selection` data source allows you to query details about an existing backup selection.

#### Usage Example

```hcl
# Query a backup selection
data "aws_backup_selection" "example" {
  plan_id      = "your-plan-id"
  selection_id = "your-selection-id"
}

# Access selection attributes
output "selection_name" {
  value = data.aws_backup_selection.example.name
}

output "selection_iam_role" {
  value = data.aws_backup_selection.example.iam_role_arn
}

output "selection_resources" {
  value = data.aws_backup_selection.example.resources
}
```

#### Available Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Display name of the backup selection |
| `iam_role_arn` | string | IAM role ARN used for backup operations |
| `resources` | list(string) | Array of resource ARNs or patterns included in the selection |

## Using Data Sources with This Module

### Querying Module-Created Selections

To query backup selections created by this module, use the plan IDs from the module outputs:

```hcl
module "backup" {
  source = "lgallard/backup/aws"

  plans = {
    production = {
      name = "production-backup-plan"
      # ... plan configuration
    }
  }
}

# Query a selection from the module's backup plan
data "aws_backup_selection" "my_selection" {
  plan_id      = module.backup.plans["production"].id
  selection_id = "selection-id-from-aws"
}
```

### Getting Selection IDs

**Important**: The `selection_id` parameter is required but not directly available as a Terraform output due to AWS API limitations. You must retrieve selection IDs using one of these methods:

#### Method 1: AWS Console
1. Navigate to AWS Backup → Backup plans
2. Select your backup plan
3. Go to "Resource assignments" tab
4. Copy the Selection ID from the list

#### Method 2: AWS CLI
```bash
# List all selections for a backup plan
aws backup list-backup-selections \
  --backup-plan-id <plan-id>

# Get specific selection details
aws backup get-backup-selection \
  --backup-plan-id <plan-id> \
  --selection-id <selection-id>
```

## Best Practices

1. **Use data sources for queries only**: Don't use data sources to manage backup selections - use the module's resource blocks instead.

2. **Cache selection IDs**: Store selection IDs in Terraform variables or AWS Systems Manager Parameter Store for easier reference.

3. **Validate before use**: Verify that selections exist before referencing them in other resources.

4. **Document dependencies**: Clearly document which resources depend on data source queries.

5. **Use tags for discovery**: Tag backup plans and selections consistently to enable easier querying.

## Examples

For comprehensive examples of using AWS Backup data sources, see:

- [Backup Selection Data Source Example](../examples/backup_selection_data_source/)

## References

- [aws_backup_selection Data Source Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/backup_selection)
- [AWS Backup API Reference](https://docs.aws.amazon.com/aws-backup/latest/devguide/API_GetBackupSelection.html)
