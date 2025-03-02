<!-- BEGIN_TF_DOCS -->
# Complete AWS Backup Audit Framework Example

This example demonstrates a comprehensive setup of AWS Backup with audit framework, controls, and reporting capabilities.

## Features

- Creates an AWS Backup Vault with lock configuration
- Implements an AWS Backup Audit Framework with controls
- Configures backup reporting with S3 bucket integration
- Sets up SNS notifications for backup events
- Implements comprehensive tagging strategy

## Usage

```hcl
# Create an SNS topic for backup notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "backup_notifications"
}

module "aws_backup_example" {
  source = "../.."

  # Vault Configuration
  vault_name     = "complete_audit_vault"
  locked         = true
  min_retention_days = 7    # Adding minimum retention
  max_retention_days = 360  # Adding maximum retention

  # Framework Configuration
  audit_framework = {
    create      = true                         # Added required create attribute
    name        = "enterprise_audit_framework"  # Changed hyphen to underscore
    description = "Enterprise Audit Framework for AWS Backup"
    control_scope = {
      tags = {
        Environment = "prod"
      }
    }
    controls = [  # Changed from map to list
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
      }
    ]
  }

  # Report Configuration
  reports = [
    {
      name            = "audit_compliance_report"  # Changed hyphen to underscore
      description     = "Audit compliance report for AWS Backup"
      formats         = ["CSV", "JSON"]
      s3_bucket_name  = "my_backup_report_bucket"  # Changed to use underscores
      report_template = "BACKUP_JOB_REPORT"
      accounts        = ["123456789012"]
      regions        = ["us-west-2"]
      framework_arns  = ["arn:aws:backup:us-west-2:123456789012:framework/enterprise_audit_framework"]  # Updated ARN to use underscore
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "backup_audit"  # Changed to use underscore
  }
}
```

## Audit Framework Configuration

This example configures an enterprise-level audit framework with the following components:

### Control Scope
- Targets resources based on environment tags
- Applies to production workloads

### Audit Controls
1. **BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN**
   - Ensures critical resources are protected by backup plans
   - Frequency: Every 24 hours
   - Minimum retention: 35 days
   - Parameters configured for frequency and retention requirements

### Reporting Configuration
- Generates CSV and JSON format reports
- Stores reports in a dedicated S3 bucket
- Covers specified AWS accounts and regions
- Uses BACKUP_JOB_REPORT template for standardized reporting

## Important Notes

1. **AWS Config Requirement**
   - For the Framework Deployment Status to be successful, you must enable AWS Config resource tracking
   - This can be configured through the AWS Console
   - Required to track configuration changes of backup resources

2. **Vault Configuration**
   - Vault is configured with lock settings
   - Minimum retention: 7 days
   - Maximum retention: 360 days
   - Ensures compliance with data retention policies

3. **SNS Notifications**
   - Backup events are published to an SNS topic
   - Enables real-time monitoring and alerting
   - Can be integrated with other notification systems

4. **Naming Conventions**
   - All resource names use underscores instead of hyphens
   - Complies with AWS Backup naming requirements
   - Consistent across all components
<!-- END_TF_DOCS -->
