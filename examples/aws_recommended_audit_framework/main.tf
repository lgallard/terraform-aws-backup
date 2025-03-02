module "aws_backup_example" {
  source = "../.."

  # Vault configuration with encryption and compliance settings
  vault_name          = var.audit_config.vault.name
  vault_kms_key_arn   = var.audit_config.vault.kms_key_arn
  vault_force_destroy = var.audit_config.vault.force_destroy

  # Enable AWS recommended backup framework
  audit_framework = {
    create      = true
    name        = var.audit_config.framework.name
    description = var.audit_config.framework.description

    controls = [
      # Ensure resources are protected by backup plans
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.audit_config.controls.backup_plan.min_retention_days)
      },
      # Enforce minimum retention period
      {
        name            = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.audit_config.controls.backup_plan.min_retention_days)
      },
      # Ensure all backups are encrypted
      {
        name            = "BACKUP_RECOVERY_POINT_ENCRYPTED"
        parameter_name  = "resourceType"
        parameter_value = "ALL"
      },
      # Enforce backup frequency
      {
        name            = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        parameter_name  = "requiredFrequencyUnit"
        parameter_value = var.audit_config.controls.backup_plan.frequency_unit
      },
      {
        name            = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        parameter_name  = "requiredFrequencyValue"
        parameter_value = tostring(var.audit_config.controls.backup_plan.frequency_value)
      },
      # Cross-Region backup copy
      {
        name            = "BACKUP_RECOVERY_POINT_CROSS_REGION"
        parameter_name  = "targetRegions"
        parameter_value = join(",", var.audit_config.controls.regions)
      },
      # Resource type specific controls
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "resourceType"
        parameter_value = var.audit_config.controls.resource_types["ebs"]
      },
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "resourceType"
        parameter_value = var.audit_config.controls.resource_types["rds"]
      },
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "resourceType"
        parameter_value = var.audit_config.controls.resource_types["aurora"]
      }
    ]

    policy_assignment = {
      opt_in_preference       = true
      policy_id               = var.audit_config.policy.id
      regions                 = var.audit_config.controls.regions
      organizational_unit_ids = var.audit_config.policy.organizational_units
    }
  }

  # Configure comprehensive backup reports
  reports = [
    {
      name            = "aws-backup-audit-report"
      description     = "AWS Backup compliance and audit report"
      formats         = var.audit_config.reporting.formats
      s3_bucket_name  = var.audit_config.reporting.bucket_name
      s3_key_prefix   = "backup-audit/"
      report_template = "BACKUP_JOB_REPORT"
      accounts        = var.audit_config.reporting.account_ids
      regions         = var.audit_config.controls.regions
    }
  ]

  tags = {
    Environment = "production"
    Framework   = "aws-recommended"
    Compliance  = "enabled"
    Encryption  = "enabled"
    CrossRegion = "enabled"
  }
}
