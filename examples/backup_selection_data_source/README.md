# Backup Selection Data Source Example

This example demonstrates how to use the `aws_backup_selection` data source to query existing backup selections, both from selections created by this module and from external backup configurations.

## Overview

The `aws_backup_selection` data source allows you to:
- **Query backup selection details** created by AWS Backup
- **Reference external selections** created outside Terraform
- **Access selection metadata** like name, IAM role, and resource patterns
- **Integrate with existing backup infrastructure** without modifying it

## Use Cases

### 1. Query Module-Created Selections
Reference backup selections created by this module to:
- Validate selection configuration
- Use selection details in other modules
- Create dependencies on backup configurations
- Audit backup coverage

### 2. Reference External Selections
Query backup selections created via:
- AWS Console
- AWS CLI
- Other Terraform configurations
- AWS Organizations backup policies

### 3. Build Complex Workflows
Use selection data to:
- Create conditional resources based on backup configuration
- Generate compliance reports
- Automate backup verification
- Integrate with monitoring systems

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Backup Module                            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Backup Plan: production-backup-plan                 │   │
│  │  Plan ID: plan-abc123                                │   │
│  │                                                       │   │
│  │  Selections:                                         │   │
│  │  ├─ EC2 Instances      (selection-id: sel-111)      │   │
│  │  ├─ RDS Databases      (selection-id: sel-222)      │   │
│  │  └─ DynamoDB Tables    (selection-id: sel-333)      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Query via Data Source
                            ▼
┌─────────────────────────────────────────────────────────────┐
│         aws_backup_selection Data Source                     │
│                                                               │
│  Input:                                                      │
│  • plan_id      = "plan-abc123"                              │
│  • selection_id = "sel-111"                                  │
│                                                               │
│  Output:                                                     │
│  • name         = "ec2_instances"                            │
│  • iam_role_arn = "arn:aws:iam::123456789012:role/..."     │
│  • resources    = ["arn:aws:ec2:*:*:instance/*"]            │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Step 1: Create Backup Configuration

```bash
# Initialize and apply the example
terraform init
terraform apply
```

This creates:
- A backup vault
- A backup plan with daily backups
- Three backup selections (EC2, RDS, DynamoDB)

### Step 2: Get Selection IDs

After the backup plan is created, use the helper outputs to easily retrieve selection IDs:

#### Option A: Use Helper Outputs (Recommended)

The example provides ready-to-run commands. Simply copy and execute them:

```bash
# View the quick start guide
terraform output usage_instructions

# Option 1: Get selections as a formatted table (easiest to read)
$(terraform output -raw cli_list_selections_table)

# Option 2: Get selections with jq (best for scripting)
$(terraform output -raw cli_extract_ids_jq)

# Option 3: Save and run the helper script
terraform output -raw helper_script > get_selections.sh
chmod +x get_selections.sh
./get_selections.sh
```

#### Option B: Manual AWS CLI

```bash
# Get the plan ID from Terraform output
PLAN_ID=$(terraform output -raw backup_plan_id)

# List all selections for this plan (table format)
aws backup list-backup-selections --backup-plan-id $PLAN_ID \
  --query 'BackupSelectionsList[*].[SelectionId,SelectionName,IamRoleArn]' \
  --output table

# Or get as JSON with jq for parsing
aws backup list-backup-selections --backup-plan-id $PLAN_ID \
  | jq -r '.BackupSelectionsList[] | "\(.SelectionName): \(.SelectionId)"'

# Raw JSON output:
aws backup list-backup-selections --backup-plan-id $PLAN_ID
```

**Example output:**
```
-------------------------------------------------------------------
|                    ListBackupSelections                          |
+----------------+-------------------+------------------------------+
|  sel-abc123    |  ec2_instances    |  arn:aws:iam::123...:role/...|
|  sel-def456    |  rds_databases    |  arn:aws:iam::123...:role/...|
|  sel-ghi789    |  dynamodb_tables  |  arn:aws:iam::123...:role/...|
+----------------+-------------------+------------------------------+
```

### Step 3: Query Selection Using Data Source

Update `main.tf` with the actual selection ID:

```hcl
data "aws_backup_selection" "ec2_selection" {
  plan_id      = module.backup_with_selections.plans["production"].id
  selection_id = "sel-abc123"  # Replace with actual ID from Step 2
}

output "ec2_selection_details" {
  value = {
    name         = data.aws_backup_selection.ec2_selection.name
    iam_role_arn = data.aws_backup_selection.ec2_selection.iam_role_arn
    resources    = data.aws_backup_selection.ec2_selection.resources
  }
}
```

Then refresh:

```bash
terraform refresh
terraform output ec2_selection_details
```

## Configuration Examples

### Example 1: Query Module-Created Selection

```hcl
# Create backup configuration
module "backup" {
  source = "lgallard/backup/aws"

  plans = {
    main = {
      name = "main-backup-plan"
      rules = [{ /* ... */ }]
      selections = {
        databases = { /* ... */ }
      }
    }
  }
}

# Query the selection
data "aws_backup_selection" "databases" {
  plan_id      = module.backup.plans["main"].id
  selection_id = "sel-xyz123"  # From AWS Console or CLI
}

# Use the selection data
output "db_backup_role" {
  value = data.aws_backup_selection.databases.iam_role_arn
}
```

### Example 2: Reference External Selection

```hcl
# Query an existing backup plan (not managed by Terraform)
data "aws_backup_plan" "external" {
  plan_id = "plan-external-123"
}

# Query a selection from the external plan
data "aws_backup_selection" "external_selection" {
  plan_id      = data.aws_backup_plan.external.id
  selection_id = "sel-external-456"
}

# Create monitoring based on external backup config
resource "aws_cloudwatch_metric_alarm" "backup_alarm" {
  alarm_name          = "backup-${data.aws_backup_selection.external_selection.name}-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsCreated"
  namespace           = "AWS/Backup"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    BackupPlanId = data.aws_backup_plan.external.id
  }
}
```

### Example 3: Conditional Resource Creation

```hcl
# Query selection to determine if specific resources are backed up
data "aws_backup_selection" "production" {
  plan_id      = var.prod_plan_id
  selection_id = var.prod_selection_id
}

# Create additional monitoring only if EC2 instances are included
locals {
  ec2_backed_up = anytrue([
    for resource in data.aws_backup_selection.production.resources :
    can(regex("arn:aws:ec2:", resource))
  ])
}

resource "aws_cloudwatch_dashboard" "ec2_backup" {
  count          = local.ec2_backed_up ? 1 : 0
  dashboard_name = "ec2-backup-monitoring"
  # Dashboard configuration...
}
```

## Data Source Attributes

The `aws_backup_selection` data source provides:

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | string | Display name of the backup selection |
| `iam_role_arn` | string | IAM role ARN used for backup operations |
| `resources` | list(string) | Array of resource ARNs or patterns |

## AWS CLI Reference

### List All Selections

```bash
# List selections for a backup plan
aws backup list-backup-selections \
  --backup-plan-id <plan-id>
```

### Get Selection Details

```bash
# Get detailed information about a selection
aws backup get-backup-selection \
  --backup-plan-id <plan-id> \
  --selection-id <selection-id>
```

### Query via Resource Tags

```bash
# Find backup plans by tag
aws backup list-backup-plans --query 'BackupPlansList[?Tags.Environment==`production`]'
```

## Integration Patterns

### Pattern 1: Backup Verification

```hcl
# Query all selections for compliance check
data "aws_backup_selection" "all_selections" {
  for_each = toset(var.selection_ids)

  plan_id      = var.plan_id
  selection_id = each.value
}

# Verify all selections use approved IAM roles
locals {
  approved_roles = ["arn:aws:iam::123456789012:role/BackupRole"]

  non_compliant_selections = [
    for k, v in data.aws_backup_selection.all_selections :
    k if !contains(local.approved_roles, v.iam_role_arn)
  ]
}

# Create alert if non-compliant selections found
resource "aws_sns_topic_subscription" "compliance_alert" {
  count     = length(local.non_compliant_selections) > 0 ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "compliance@example.com"
}
```

### Pattern 2: Cross-Account Backup Validation

```hcl
# Query backup selection in management account
provider "aws" {
  alias = "management"
  # Management account credentials
}

data "aws_backup_selection" "central" {
  provider = aws.management

  plan_id      = var.central_plan_id
  selection_id = var.central_selection_id
}

# Verify member accounts are included
locals {
  backed_up_accounts = [
    for resource in data.aws_backup_selection.central.resources :
    regex("arn:aws:.*:.*:(\\d+):.*", resource)[0]
  ]

  missing_accounts = setsubtract(
    var.required_accounts,
    local.backed_up_accounts
  )
}
```

## Limitations

### Selection ID Requirement
The data source requires a `selection_id`, which must be obtained from:
- AWS Console: Backup → Backup plans → [Plan Name] → Resource assignments
- AWS CLI: `aws backup list-backup-selections --backup-plan-id <plan-id>`
- Terraform: Selection IDs are not directly output by the module (AWS limitation)

### Read-Only Operation
The data source only reads existing selections. To modify selections, use the module's resource blocks.

### No List Operation
The data source cannot list all selections for a plan. Use AWS CLI for discovery:
```bash
aws backup list-backup-selections --backup-plan-id <plan-id>
```

## Troubleshooting

### Error: Selection Not Found

```
Error: reading Backup Selection: ResourceNotFoundException
```

**Solutions:**
1. Verify the selection exists:
   ```bash
   aws backup get-backup-selection \
     --backup-plan-id <plan-id> \
     --selection-id <selection-id>
   ```

2. Check the plan ID is correct:
   ```bash
   aws backup list-backup-plans
   ```

3. Ensure you have IAM permissions:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "backup:GetBackupSelection",
       "backup:ListBackupSelections"
     ],
     "Resource": "*"
   }
   ```

### Selection ID Not Available

If you need to query selections but don't have the ID:

```bash
# Get all selection IDs for a plan
aws backup list-backup-selections \
  --backup-plan-id <plan-id> \
  --query 'BackupSelectionsList[*].SelectionId' \
  --output text
```

## Best Practices

1. **Use Data Sources for Queries Only**: Don't use data sources to manage backup selections - use the module resources instead.

2. **Cache Selection IDs**: Store selection IDs in Terraform variables or SSM parameters for easier reference.

3. **Validate Before Use**: Check that selections exist before referencing them in other resources.

4. **Use Tags for Discovery**: Tag backup plans and selections consistently to enable easier querying.

5. **Document Dependencies**: Clearly document which resources depend on data source queries.

## Related Examples

- **[Complete Backup Configuration](../complete_backup/)** - Full backup setup with multiple selections
- **[Selection by Tags](../selection_by_tags/)** - Dynamic resource selection patterns
- **[Selection by Conditions](../selection_by_conditions/)** - Advanced selection criteria

## AWS Documentation

- [aws_backup_selection Data Source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/backup_selection)
- [AWS Backup Resource Selections](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html#creating-a-backup-selection)
- [AWS Backup API Reference](https://docs.aws.amazon.com/aws-backup/latest/devguide/API_GetBackupSelection.html)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.22.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_backup_with_selections"></a> [backup\_with\_selections](#module\_backup\_with\_selections) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS region for backup resources | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources | `map(string)` | <pre>{<br/>  "Environment": "example",<br/>  "Purpose": "BackupSelectionDataSource",<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the backup vault | `string` | `"backup-selection-datasource-vault"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_plan_arn"></a> [backup\_plan\_arn](#output\_backup\_plan\_arn) | ARN of the created backup plan |
| <a name="output_backup_plan_id"></a> [backup\_plan\_id](#output\_backup\_plan\_id) | ID of the created backup plan (use this with data source) |
| <a name="output_backup_plan_name"></a> [backup\_plan\_name](#output\_backup\_plan\_name) | Name of the created backup plan |
| <a name="output_usage_instructions"></a> [usage\_instructions](#output\_usage\_instructions) | Instructions for using the backup selection data source |
<!-- END_TF_DOCS -->
