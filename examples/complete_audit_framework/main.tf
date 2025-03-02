# Create an SNS topic for backup notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "backup-notifications"
}

module "aws_backup_example" {
  source = "../../"

  # Vault configuration
  vault_name        = "audit-framework-vault"
  vault_kms_key_arn = var.kms_key_arn

  # Enable notifications
  notifications = {
    sns_topic_arn = aws_sns_topic.backup_notifications.arn
    backup_vault_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "AUDIT_REPORT_CREATED"
    ]
  }

  # Configure AWS Backup Audit Manager framework
  audit_framework = {
    create      = true
    name        = var.audit_framework_name
    description = var.audit_framework_description

    controls = [
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.retention_period)
      },
      {
        name            = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.retention_period)
      },
      {
        name            = "BACKUP_RECOVERY_POINT_ENCRYPTED"
        parameter_name  = "resourceType"
        parameter_value = var.resource_types["all"]
      },
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "resourceType"
        parameter_value = var.resource_types["rds"]
      },
      {
        name            = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        parameter_name  = "requiredFrequencyUnit"
        parameter_value = var.frequency_unit
      }
    ]

    policy_assignment = {
      opt_in_preference       = true
      policy_id               = var.backup_policy_id
      regions                 = var.backup_regions
      organizational_unit_ids = var.organizational_units
    }
  }

  # Configure backup reports
  reports = [
    {
      name            = "audit-compliance-report"
      description     = "Daily backup compliance report"
      formats         = ["CSV", "JSON"]
      s3_bucket_name  = var.report_bucket
      s3_key_prefix   = "audit-reports/"
      report_template = "BACKUP_JOB_REPORT"
      accounts        = var.account_ids
      regions         = var.backup_regions
    }
  ]

  tags = {
    Environment = "production"
    Project     = "backup-audit"
    Owner       = "backup-team"
    Compliance  = "required"
  }
}
