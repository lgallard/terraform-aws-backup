<!-- BEGIN_TF_DOCS -->
# AWS Recommended Backup Audit Framework Example

This example demonstrates how to implement AWS's recommended backup audit framework configuration, including comprehensive controls, reporting, and vault settings.

## Features

- Implements AWS recommended backup audit controls
- Configures vault with encryption and retention settings
- Sets up comprehensive backup reporting
- Implements organization-wide policy assignments
- Uses AWS best practices for backup auditing

## Usage

```hcl
module "aws_backup_example" {
  source = "../.."

  # Vault configuration with encryption and compliance settings
  vault_name          = "aws_backup_vault"
  vault_kms_key_arn   = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  vault_force_destroy = true
  min_retention_days  = 7
  max_retention_days  = 360
  locked             = true
  changeable_for_days = 3

  # Backup plan configuration
  plan_name = "aws_recommended_backup_plan"

  # Backup rules configuration
  rules = [
    {
      name                     = "rule_1"
      schedule                = "cron(0 5 ? * * *)"
      start_window            = 480
      completion_window       = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      recovery_point_tags = {
        Environment = "prod"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 180
          }
        }
      ]
    }
  ]

  # Backup selection configuration
  selections = [
    {
      name = "resource_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "prod"
      }
      resources = [
        "arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
        "arn:aws:ec2:us-west-2:123456789012:volume/vol-12345678"
      ]
    }
  ]

  # Enable AWS recommended backup framework
  audit_framework = {
    create      = true
    name        = "aws_recommended_framework"
    description = "AWS Recommended Backup Framework"
    control_scope = {
      tags = {
        Environment = "prod"
      }
    }
    controls = [
      {
        control_name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        name         = "backup_resources_protected_by_backup_plan"
        input_parameters = [
          {
            parameter_name  = "requiredBackupPlanFrequencyUnit"
            parameter_value = "hours"
          },
          {
            parameter_name  = "requiredBackupPlanFrequencyValue"
            parameter_value = "24"
          },
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        name         = "backup_plan_min_frequency_and_retention"
        input_parameters = [
          {
            parameter_name  = "requiredFrequencyUnit"
            parameter_value = "hours"
          },
          {
            parameter_name  = "requiredFrequencyValue"
            parameter_value = "24"
          },
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
        name         = "backup_recovery_point_min_retention"
        input_parameters = [
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
        name         = "backup_recovery_point_encrypted"
        input_parameters = []
      },
      {
        control_name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
        name         = "backup_resources_protected_by_vault_lock"
        input_parameters = [
          {
            parameter_name  = "maxRetentionDays"
            parameter_value = "100"
          }
        ]
      }
    ]

    policy_assignment = {
      opt_in_preference       = true
      policy_id              = "backup-policy-id"
      regions                = ["us-west-2"]
      organizational_unit_ids = ["ou-1234-12345678"]
    }
  }

  # Configure comprehensive backup reports
  reports = [
    {
      name            = "aws_backup_audit_report"
      description     = "AWS Backup compliance and audit report"
      report_template = "BACKUP_JOB_REPORT"
      s3_bucket_name  = "my-backup-reports-bucket"
      s3_key_prefix   = "backup_audit"
      formats         = ["CSV", "JSON"]
      framework_arns  = ["arn:aws:backup:us-west-2:123456789012:framework/aws_recommended_framework"]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "backup_audit"
    Framework   = "aws_recommended"
    Compliance  = "enabled"
    Encryption  = "enabled"
    CrossRegion = "enabled"
  }
}
```

## Audit Framework Configuration

### Control Scope
- Targets resources based on environment tags
- Applies to production workloads

### Implemented Controls

1. **BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN**
   - Ensures resources are protected by backup plans
   - Frequency: Every 24 hours
   - Minimum retention: 35 days

2. **BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK**
   - Validates backup frequency and retention periods
   - Minimum frequency: Every 24 hours
   - Minimum retention: 35 days

3. **BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK**
   - Ensures recovery points meet minimum retention
   - Required retention: 35 days

4. **BACKUP_RECOVERY_POINT_ENCRYPTED**
   - Enforces encryption of recovery points
   - No parameters required

5. **BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK**
   - Ensures vault lock protection
   - Maximum retention: 100 days

### Policy Assignment
- Opt-in preference enabled
- Applies to specified organizational units
- Region-specific implementation
- Managed through policy ID

## Vault Configuration

- KMS encryption enabled
- Minimum retention: 7 days
- Maximum retention: 360 days
- Force destroy option available

## Reporting Configuration

- Generates detailed backup audit reports
- Multiple format support (CSV, JSON)
- S3 bucket integration
- Framework-specific reporting

## Important Notes

1. **AWS Config Requirement**
   - AWS Config must be enabled for framework deployment
   - Required for tracking backup resource changes
   - Enables control evaluation

2. **Organization Requirements**
   - Requires AWS Organizations setup
   - Policy assignments at organization level
   - Organizational unit targeting

3. **Security Considerations**
   - KMS encryption for vault
   - Encrypted recovery points
   - Secure report storage in S3

4. **Naming Conventions**
   - Uses underscores instead of hyphens
   - Complies with AWS naming requirements
   - Consistent across all resources
<!-- END_TF_DOCS -->
