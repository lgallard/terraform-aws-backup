# Create an SNS topic for backup notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "backup_notifications"
}

module "aws_backup_example" {
  source = "../.."

  # Vault Configuration
  vault_name         = "complete_audit_vault"
  locked             = true
  min_retention_days = 7
  max_retention_days = 360

  # Framework Configuration
  audit_framework = {
    create      = true
    name        = "enterprise_audit_framework"
    description = "Enterprise Audit Framework for AWS Backup"
    control_scope = {
      tags = {
        Environment = "prod"
      }
    }
    controls = [ # Changed from map to list
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
      name            = "audit_compliance_report"
      description     = "Audit compliance report for AWS Backup"
      formats         = ["CSV", "JSON"]
      s3_bucket_name  = "my_backup_report_bucket"
      report_template = "BACKUP_JOB_REPORT"
      accounts        = ["123456789012"]
      regions         = ["us-west-2"]
      framework_arns  = ["arn:aws:backup:us-west-2:123456789012:framework/enterprise_audit_framework"]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "backup_audit"
  }
}
