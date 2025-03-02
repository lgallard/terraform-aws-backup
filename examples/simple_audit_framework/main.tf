module "aws_backup_example" {
  source = "../../"

  # Enable AWS Backup Audit Manager framework
  audit_framework = {
    create      = true
    name        = var.audit_config.framework.name
    description = var.audit_config.framework.description

    controls = [
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.audit_config.controls.retention_period)
      },
      {
        name            = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
        parameter_name  = "requiredRetentionDays"
        parameter_value = tostring(var.audit_config.controls.retention_period)
      },
      {
        name            = "BACKUP_RECOVERY_POINT_ENCRYPTED"
        parameter_name  = "resourceType"
        parameter_value = var.audit_config.controls.resource_type
      }
    ]
  }

  tags = {
    Environment = "test"
    Project     = "backup-audit"
  }
}
