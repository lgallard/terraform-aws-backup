# Compliance Backup Outputs

output "backup_vault_name" {
  description = "Name of the compliance backup vault"
  value       = module.compliance_backup.backup_vault_name
}

output "backup_vault_arn" {
  description = "ARN of the compliance backup vault"
  value       = module.compliance_backup.backup_vault_arn
}

output "backup_vault_locked" {
  description = "Whether the backup vault is locked for compliance"
  value       = var.enable_vault_lock
}

output "vault_lock_configuration" {
  description = "Vault lock configuration details"
  value = var.enable_vault_lock ? {
    min_retention_days  = var.min_retention_days
    max_retention_days  = var.max_retention_days
    changeable_for_days = var.changeable_for_days
  } : null
}

output "backup_plan_name" {
  description = "Name of the compliance backup plan"
  value       = module.compliance_backup.backup_plan_name
}

output "backup_plan_arn" {
  description = "ARN of the compliance backup plan"
  value       = module.compliance_backup.backup_plan_arn
}

output "backup_selection_name" {
  description = "Name of the compliance backup selection"
  value       = module.compliance_backup.backup_selection_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for compliance backups"
  value       = module.compliance_backup.backup_role_arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for backup encryption"
  value       = aws_kms_key.backup_key.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for backup encryption"
  value       = aws_kms_key.backup_key.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for backup encryption"
  value       = aws_kms_alias.backup_key_alias.name
}

output "audit_framework_name" {
  description = "Name of the compliance audit framework"
  value       = var.enable_audit_framework ? module.compliance_audit[0].audit_framework_name : null
}

output "audit_framework_arn" {
  description = "ARN of the compliance audit framework"
  value       = var.enable_audit_framework ? module.compliance_audit[0].audit_framework_arn : null
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail for audit logging"
  value       = var.enable_cloudtrail ? aws_cloudtrail.compliance_audit[0].name : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail for audit logging"
  value       = var.enable_cloudtrail ? aws_cloudtrail.compliance_audit[0].arn : null
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard for compliance monitoring"
  value = var.enable_dashboard ? "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.compliance_dashboard[0].dashboard_name}" : null
}

output "backup_failure_alarm_arn" {
  description = "ARN of the backup failure CloudWatch alarm"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.backup_compliance_failure[0].arn : null
}

output "missing_backup_alarm_arn" {
  description = "ARN of the missing backup CloudWatch alarm"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.backup_compliance_missing[0].arn : null
}

output "compliance_summary" {
  description = "Summary of compliance configuration"
  value = {
    framework              = var.compliance_framework
    vault_locked          = var.enable_vault_lock
    encryption_enabled    = true
    audit_framework       = var.enable_audit_framework
    monitoring_enabled    = var.enable_monitoring
    reporting_enabled     = var.enable_reports
    cloudtrail_enabled    = var.enable_cloudtrail
    retention_days        = var.retention_days
    min_retention_days    = var.min_retention_days
    max_retention_days    = var.max_retention_days
    cold_storage_days     = var.cold_storage_after_days
    backup_frequency      = var.backup_schedule
  }
}

output "compliance_checklist" {
  description = "Compliance implementation checklist"
  value = {
    data_encryption = {
      status      = "✅ Implemented"
      description = "Customer-managed KMS key with automatic rotation"
      details     = "KMS key: ${aws_kms_key.backup_key.key_id}"
    }
    immutable_backups = {
      status      = var.enable_vault_lock ? "✅ Implemented" : "❌ Not enabled"
      description = "Vault lock prevents deletion/modification of backups"
      details     = var.enable_vault_lock ? "Locked with ${var.changeable_for_days} day grace period" : "Enable vault_lock for compliance"
    }
    audit_framework = {
      status      = var.enable_audit_framework ? "✅ Implemented" : "❌ Not enabled"
      description = "AWS Backup Audit Manager framework"
      details     = var.enable_audit_framework ? "${var.compliance_framework} controls applied" : "Enable audit_framework for compliance"
    }
    monitoring_alerts = {
      status      = var.enable_monitoring ? "✅ Implemented" : "❌ Not enabled"
      description = "CloudWatch alarms for backup failures and missing backups"
      details     = var.enable_monitoring ? "SNS notifications configured" : "Enable monitoring for compliance"
    }
    audit_logging = {
      status      = var.enable_cloudtrail ? "✅ Implemented" : "⚠️ Optional"
      description = "CloudTrail logging for backup API calls"
      details     = var.enable_cloudtrail ? "Audit logs stored in S3" : "Consider enabling for enhanced compliance"
    }
    compliance_reporting = {
      status      = var.enable_reports ? "✅ Implemented" : "❌ Not enabled"
      description = "Automated compliance reports"
      details     = var.enable_reports ? "Reports generated to S3" : "Enable reports for compliance documentation"
    }
    retention_policy = {
      status      = var.retention_days >= 90 ? "✅ Compliant" : "⚠️ Review required"
      description = "Backup retention meets ${var.compliance_framework} requirements"
      details     = "${var.retention_days} days retention configured"
    }
  }
}