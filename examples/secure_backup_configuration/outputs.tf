# Outputs for secure backup configuration

output "backup_vault_id" {
  description = "ID of the backup vault"
  value       = module.backup.backup_vault_id
}

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.backup.backup_vault_arn
}

output "backup_vault_recovery_points" {
  description = "Number of recovery points in the backup vault"
  value       = module.backup.backup_vault_recovery_points
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = module.backup.backup_plan_id
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = module.backup.backup_plan_arn
}

output "backup_plan_version" {
  description = "Version of the backup plan"
  value       = module.backup.backup_plan_version
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = module.backup.backup_role_arn
}

output "backup_role_name" {
  description = "Name of the backup IAM role"
  value       = module.backup.backup_role_name
}

# Security-related outputs
output "backup_vault_kms_key_arn" {
  description = "ARN of the KMS key used for backup vault encryption"
  value       = aws_kms_key.backup_key.arn
}

output "backup_vault_kms_key_id" {
  description = "ID of the KMS key used for backup vault encryption"
  value       = aws_kms_key.backup_key.key_id
}

output "cross_region_vault_arn" {
  description = "ARN of the cross-region backup vault"
  value       = var.enable_cross_region_backup ? aws_backup_vault.cross_region_vault[0].arn : null
}

output "cross_region_kms_key_arn" {
  description = "ARN of the cross-region KMS key"
  value       = var.enable_cross_region_backup ? aws_kms_key.cross_region_backup_key[0].arn : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for backup notifications"
  value       = aws_sns_topic.backup_notifications.arn
}

output "sns_kms_key_arn" {
  description = "ARN of the KMS key used for SNS encryption"
  value       = aws_kms_key.sns_key.arn
}

# Monitoring outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_logs.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.backup_dashboard.dashboard_name}"
}

# Compliance outputs
output "security_compliance_summary" {
  description = "Summary of security compliance features enabled"
  value = {
    vault_lock_enabled          = var.enable_vault_lock
    customer_managed_kms        = true
    encryption_at_rest          = true
    cross_region_backup_enabled = var.enable_cross_region_backup
    monitoring_enabled          = true
    notifications_enabled       = true
    compliance_framework        = var.compliance_framework
    min_retention_days          = var.min_retention_days
    max_retention_days          = var.max_retention_days
  }
}

# Security monitoring outputs
output "security_alarms" {
  description = "List of security-related CloudWatch alarms"
  value = {
    backup_job_failed           = aws_cloudwatch_metric_alarm.backup_job_failed.alarm_name
    backup_job_success          = aws_cloudwatch_metric_alarm.backup_job_success.alarm_name
    kms_key_unusual_usage       = aws_cloudwatch_metric_alarm.kms_key_usage.alarm_name
    backup_vault_unusual_access = aws_cloudwatch_metric_alarm.backup_vault_access.alarm_name
  }
}