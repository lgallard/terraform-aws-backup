# Migration Guide

This guide provides step-by-step instructions for migrating between major versions of the terraform-aws-backup module.

## Table of Contents
- [General Migration Steps](#general-migration-steps)
- [Migration from v1.x to v2.x](#migration-from-v1x-to-v2x)
- [Migration from v0.x to v1.x](#migration-from-v0x-to-v1x)
- [Breaking Changes Summary](#breaking-changes-summary)
- [State Migration](#state-migration)
- [Rollback Procedures](#rollback-procedures)

## General Migration Steps

### 1. Backup Current State
Before any migration, always backup your Terraform state:

```bash
# Backup state file
cp terraform.tfstate terraform.tfstate.backup

# If using remote state, backup the state file
terraform state pull > terraform.tfstate.backup
```

### 2. Review Release Notes
Check the module's release notes for breaking changes:
- [GitHub Releases](https://github.com/lgallard/terraform-aws-backup/releases)
- [CHANGELOG.md](CHANGELOG.md)

### 3. Plan Migration
1. Test migration in a non-production environment
2. Schedule maintenance window for production changes
3. Prepare rollback plan

### 4. Execute Migration
1. Update module version
2. Update configuration for breaking changes
3. Run `terraform plan` to review changes
4. Apply changes with `terraform apply`

## Migration from v1.x to v2.x

### Breaking Changes Overview

#### 1. Variable Structure Changes
- `backup_selections` variable structure has been updated
- `plans` variable now uses a map instead of list
- New validation rules added for security compliance

#### 2. Resource Naming Changes
- Backup vault names now include region suffix by default
- IAM role names have been updated for consistency

#### 3. New Security Features
- Enhanced validation for vault names and KMS keys
- Mandatory service-linked role creation
- Improved cross-region backup support

### Step-by-Step Migration

#### Step 1: Update Module Version
```hcl
# Before
module "backup" {
  source = "lgallard/backup/aws"
  version = "~> 1.0"
  # ... configuration
}

# After
module "backup" {
  source = "lgallard/backup/aws"
  version = "~> 2.0"
  # ... configuration
}
```

#### Step 2: Update Variable Structure

##### backup_selections Variable
```hcl
# Before (v1.x)
backup_selections = [
  {
    name = "selection1"
    resources = ["*"]
    tags = {
      Environment = "production"
    }
  }
]

# After (v2.x)
backup_selections = {
  "selection1" = {
    resources = ["*"]
    tags = {
      Environment = "production"
    }
  }
}
```

##### plans Variable
```hcl
# Before (v1.x)
plans = [
  {
    name = "daily-backup"
    rules = [
      {
        name = "daily"
        schedule = "cron(0 2 * * ? *)"
        lifecycle = {
          delete_after = 30
        }
      }
    ]
  }
]

# After (v2.x)
plans = {
  "daily-backup" = {
    rules = [
      {
        name = "daily"
        schedule = "cron(0 2 * * ? *)"
        lifecycle = {
          delete_after = 30
        }
      }
    ]
  }
}
```

#### Step 3: Handle Security Validation
New validation rules may require configuration updates:

```hcl
# Update vault names to comply with security patterns
vault_name = "backup-vault-prod"  # Avoid 'test', 'temp', 'delete'

# Use customer-managed KMS keys
vault_kms_key_arn = aws_kms_key.backup.arn  # Not alias/aws/backup

# Update IAM role if specified
iam_role_arn = aws_iam_role.backup.arn  # Avoid Admin/PowerUser roles
```

#### Step 4: State Migration
Some resources may need to be moved in the state:

```bash
# Move backup selections from list to map
terraform state mv 'module.backup.aws_backup_selection.selection[0]' 'module.backup.aws_backup_selection.selection["selection1"]'

# Move backup plans from list to map
terraform state mv 'module.backup.aws_backup_plan.plan[0]' 'module.backup.aws_backup_plan.plan["daily-backup"]'
```

#### Step 5: Verify Migration
```bash
# Check planned changes
terraform plan

# Apply changes
terraform apply
```

### Common Migration Issues

#### Issue 1: Validation Errors
```
Error: Invalid vault name pattern
```

**Solution**: Update vault names to comply with security patterns:
```hcl
vault_name = "backup-vault-production"  # Replace "test-vault"
```

#### Issue 2: State Conflicts
```
Error: Resource already exists
```

**Solution**: Use `terraform import` or state manipulation:
```bash
# Import existing resources
terraform import 'module.backup.aws_backup_vault.vault' backup-vault-name

# Or remove from state and recreate
terraform state rm 'module.backup.aws_backup_vault.vault'
```

#### Issue 3: KMS Key Issues
```
Error: KMS key not allowed
```

**Solution**: Use customer-managed KMS keys:
```hcl
resource "aws_kms_key" "backup" {
  description             = "Backup vault encryption key"
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Migration from v0.x to v1.x

### Breaking Changes Overview

#### 1. Resource Structure Changes
- Introduction of `plans` variable for better organization
- Consolidation of backup selection variables
- New IAM role management options

#### 2. Naming Conventions
- Standardized resource naming
- Consistent tagging approach

### Step-by-Step Migration

#### Step 1: Update Module Version
```hcl
# Before
module "backup" {
  source = "lgallard/backup/aws"
  version = "~> 0.9"
  # ... configuration
}

# After
module "backup" {
  source = "lgallard/backup/aws"
  version = "~> 1.0"
  # ... configuration
}
```

#### Step 2: Migrate to plans Variable
```hcl
# Before (v0.x)
rule_name = "daily-backup"
rule_schedule = "cron(0 2 * * ? *)"
rule_lifecycle_delete_after = 30

selection_name = "ec2-instances"
selection_resources = ["arn:aws:ec2:*:*:instance/*"]

# After (v1.x)
plans = {
  "daily-backup" = {
    rules = [
      {
        name = "daily"
        schedule = "cron(0 2 * * ? *)"
        lifecycle = {
          delete_after = 30
        }
      }
    ]
    selections = {
      "ec2-instances" = {
        resources = ["arn:aws:ec2:*:*:instance/*"]
      }
    }
  }
}
```

#### Step 3: Update State References
```bash
# Move individual rule to plans structure
terraform state mv 'module.backup.aws_backup_plan.backup_plan' 'module.backup.aws_backup_plan.plan["daily-backup"]'

# Move selections
terraform state mv 'module.backup.aws_backup_selection.backup_selection' 'module.backup.aws_backup_selection.selection["ec2-instances"]'
```

## Breaking Changes Summary

### v2.x Breaking Changes
- **Variable Structure**: `backup_selections` and `plans` now use maps instead of lists
- **Validation**: Enhanced security validation for vault names, KMS keys, and IAM roles
- **Resource Naming**: Standardized resource naming conventions
- **Security**: Mandatory security patterns and validations

### v1.x Breaking Changes
- **Configuration Structure**: Introduction of `plans` variable
- **Resource Organization**: Consolidation of backup rules and selections
- **IAM Management**: New IAM role management options

## State Migration

### Using terraform state Commands

#### Moving Resources in State
```bash
# Move from list to map
terraform state mv 'module.backup.aws_backup_selection.selection[0]' 'module.backup.aws_backup_selection.selection["selection-name"]'

# Move between modules
terraform state mv 'module.backup.aws_backup_plan.plan' 'module.backup_v2.aws_backup_plan.plan["default"]'
```

#### Importing Existing Resources
```bash
# Import backup vault
terraform import 'module.backup.aws_backup_vault.vault' backup-vault-name

# Import backup plan
terraform import 'module.backup.aws_backup_plan.plan["default"]' backup-plan-id
```

### Using terraform state replace-provider
For provider version changes:
```bash
terraform state replace-provider registry.terraform.io/hashicorp/aws registry.terraform.io/hashicorp/aws
```

## Rollback Procedures

### Immediate Rollback

#### 1. Restore State Backup
```bash
# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Or restore remote state
terraform state push terraform.tfstate.backup
```

#### 2. Revert Module Version
```hcl
module "backup" {
  source = "lgallard/backup/aws"
  version = "~> 1.0"  # Revert to previous version
  # ... previous configuration
}
```

#### 3. Apply Previous Configuration
```bash
terraform init -upgrade
terraform plan
terraform apply
```

### Gradual Rollback

#### 1. Create Parallel Infrastructure
```hcl
# Keep old configuration
module "backup_old" {
  source = "lgallard/backup/aws"
  version = "~> 1.0"
  # ... old configuration
}

# New configuration
module "backup_new" {
  source = "lgallard/backup/aws"
  version = "~> 2.0"
  # ... new configuration
}
```

#### 2. Migrate Data Gradually
1. Test new configuration with non-critical resources
2. Gradually move resources to new configuration
3. Remove old configuration when stable

#### 3. Cleanup
```bash
# Remove old module
terraform state rm 'module.backup_old'
```

## Testing Migration

### Pre-Migration Testing

#### 1. Validation Tests
```bash
# Test configuration syntax
terraform validate

# Test plan without applying
terraform plan
```

#### 2. State Verification
```bash
# Check current state
terraform state list

# Show specific resource state
terraform state show 'module.backup.aws_backup_vault.vault'
```

### Post-Migration Testing

#### 1. Verify Resources
```bash
# List backup vaults
aws backup list-backup-vaults

# List backup plans
aws backup list-backup-plans

# Test backup job
aws backup start-backup-job --backup-vault-name vault-name --resource-arn resource-arn --iam-role-arn role-arn
```

#### 2. Monitor Backup Operations
```bash
# Check backup job status
aws backup list-backup-jobs --by-backup-vault-name vault-name

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/Backup --metric-name NumberOfBackupJobsCompleted --start-time 2023-01-01T00:00:00Z --end-time 2023-01-02T00:00:00Z --period 3600 --statistics Sum
```

## Support and Resources

### Getting Help
- **GitHub Issues**: [terraform-aws-backup issues](https://github.com/lgallard/terraform-aws-backup/issues)
- **Documentation**: [README.md](README.md)
- **AWS Support**: Open a support case for AWS Backup issues

### Additional Resources
- [Terraform State Management](https://www.terraform.io/docs/state/index.html)
- [AWS Backup User Guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/)
- [Terraform Module Best Practices](https://www.terraform.io/docs/modules/index.html)

## Related Documentation
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting guide
- [BEST_PRACTICES.md](BEST_PRACTICES.md) - Best practices
- [PERFORMANCE.md](PERFORMANCE.md) - Performance optimization