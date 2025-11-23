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

## Troubleshooting

### Common Errors and Solutions

#### Error: Selection Not Found (ResourceNotFoundException)

**Error Message:**
```
Error: reading Backup Selection (plan-abc123:sel-xyz789): ResourceNotFoundException:
Backup selection 'sel-xyz789' not found
```

**Causes:**
- The selection ID is incorrect or doesn't exist
- The selection was deleted
- The selection belongs to a different backup plan
- Typo in the selection ID

**Solutions:**

1. Verify the selection exists:
   ```bash
   aws backup get-backup-selection \
     --backup-plan-id <plan-id> \
     --selection-id <selection-id>
   ```

2. List all selections for the backup plan:
   ```bash
   aws backup list-backup-selections \
     --backup-plan-id <plan-id> \
     --query 'BackupSelectionsList[*].[SelectionId,SelectionName]' \
     --output table
   ```

3. Check if you're using the correct AWS region:
   ```bash
   # Verify region matches your Terraform configuration
   aws backup list-backup-plans --region us-east-1
   ```

#### Error: Backup Plan Not Found

**Error Message:**
```
Error: reading Backup Selection: InvalidParameterValueException:
Backup plan not found: plan-abc123
```

**Causes:**
- The plan ID is incorrect
- The backup plan was deleted
- Wrong AWS region or account
- Plan ID from different environment

**Solutions:**

1. Verify the plan exists:
   ```bash
   aws backup get-backup-plan --backup-plan-id <plan-id>
   ```

2. List all backup plans in the current region:
   ```bash
   aws backup list-backup-plans \
     --query 'BackupPlansList[*].[BackupPlanId,BackupPlanName]' \
     --output table
   ```

3. Check if the plan is in a different region:
   ```bash
   # List plans in all regions
   for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
     echo "Checking $region..."
     aws backup list-backup-plans --region $region --query 'BackupPlansList[*].[BackupPlanId,BackupPlanName]' --output text
   done
   ```

#### Error: Access Denied (AccessDeniedException)

**Error Message:**
```
Error: reading Backup Selection: AccessDeniedException:
User: arn:aws:iam::123456789012:user/terraform is not authorized to perform:
backup:GetBackupSelection on resource: arn:aws:backup:us-east-1:123456789012:backup-plan:plan-abc123
```

**Causes:**
- Missing IAM permissions
- Incorrect IAM policy attached
- Resource-based policy denying access
- Service Control Policy (SCP) restrictions

**Solutions:**

1. Add required IAM permissions to your user/role:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "backup:GetBackupSelection",
           "backup:ListBackupSelections",
           "backup:GetBackupPlan",
           "backup:ListBackupPlans"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

2. For least-privilege access, scope to specific resources:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "backup:GetBackupSelection",
           "backup:ListBackupSelections"
         ],
         "Resource": [
           "arn:aws:backup:*:123456789012:backup-plan:*"
         ]
       }
     ]
   }
   ```

3. Verify current IAM permissions:
   ```bash
   # Check if you have the required permissions
   aws backup list-backup-plans
   aws backup list-backup-selections --backup-plan-id <plan-id>
   ```

4. If using AWS Organizations, check for SCP restrictions:
   ```bash
   aws organizations list-policies-for-target \
     --target-id <account-id> \
     --filter SERVICE_CONTROL_POLICY
   ```

#### Error: Invalid Parameter

**Error Message:**
```
Error: Invalid value for "selection_id": string required
```

**Causes:**
- Selection ID is null or empty
- Variable not properly defined
- Missing required parameter

**Solutions:**

1. Ensure the selection_id is properly set:
   ```hcl
   data "aws_backup_selection" "example" {
     plan_id      = var.plan_id
     selection_id = var.selection_id != "" ? var.selection_id : "sel-default"
   }
   ```

2. Add validation to variables:
   ```hcl
   variable "selection_id" {
     type        = string
     description = "Backup selection ID"

     validation {
       condition     = can(regex("^sel-[a-z0-9]+$", var.selection_id))
       error_message = "Selection ID must start with 'sel-' followed by alphanumeric characters."
     }
   }
   ```

#### Error: Throttling (TooManyRequestsException)

**Error Message:**
```
Error: reading Backup Selection: TooManyRequestsException:
Rate exceeded
```

**Causes:**
- Too many API calls in a short period
- AWS Backup API rate limits exceeded
- Multiple Terraform runs simultaneously

**Solutions:**

1. Add retry logic in Terraform provider configuration:
   ```hcl
   provider "aws" {
     region = var.region

     retry_mode      = "adaptive"
     max_retries     = 10
   }
   ```

2. Use `depends_on` to sequence data source queries:
   ```hcl
   data "aws_backup_selection" "selection1" {
     plan_id      = var.plan_id
     selection_id = var.selection_id_1
   }

   data "aws_backup_selection" "selection2" {
     plan_id      = var.plan_id
     selection_id = var.selection_id_2

     depends_on = [data.aws_backup_selection.selection1]
   }
   ```

3. Reduce concurrent operations by running terraform with `-parallelism`:
   ```bash
   terraform apply -parallelism=1
   ```

### Getting Help

If you encounter other issues:

1. **Check AWS Backup service status**: https://status.aws.amazon.com/
2. **Review Terraform logs**: Set `TF_LOG=DEBUG` for detailed output
3. **Consult AWS Backup quotas**: https://docs.aws.amazon.com/aws-backup/latest/devguide/service-quotas.html
4. **Open an issue**: Report bugs or request features at https://github.com/lgallard/terraform-aws-backup/issues

## Examples

For comprehensive examples of using AWS Backup data sources, see:

- [Backup Selection Data Source Example](../examples/backup_selection_data_source/)

## References

- [aws_backup_selection Data Source Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/backup_selection)
- [AWS Backup API Reference](https://docs.aws.amazon.com/aws-backup/latest/devguide/API_GetBackupSelection.html)
