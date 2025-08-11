# Outputs for secure backup configuration

output "backup_vault_id" {
  description = "ID of the backup vault"
  value       = module.backup.vault_id
}

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "backup_vault_recovery_points" {
  description = "Number of recovery points in the backup vault"
  value       = module.backup.vault_recovery_points
}

output "backup_kms_key_id" {
  description = "ID of the backup KMS key"
  value       = aws_kms_key.backup_key.key_id
}

output "backup_kms_key_arn" {
  description = "ARN of the backup KMS key"
  value       = aws_kms_key.backup_key.arn
}

output "backup_kms_alias_name" {
  description = "Name of the backup KMS key alias"
  value       = aws_kms_alias.backup_key.name
}

# Cross-region outputs (conditional)
output "cross_region_vault_id" {
  description = "ID of the cross-region backup vault"
  value       = var.enable_cross_region_backup ? aws_backup_vault.cross_region_vault[0].id : null
}

output "cross_region_vault_arn" {
  description = "ARN of the cross-region backup vault"
  value       = var.enable_cross_region_backup ? aws_backup_vault.cross_region_vault[0].arn : null
}

output "cross_region_kms_key_id" {
  description = "ID of the cross-region backup KMS key"
  value       = var.enable_cross_region_backup ? aws_kms_key.cross_region_backup_key[0].key_id : null
}

output "cross_region_kms_key_arn" {
  description = "ARN of the cross-region backup KMS key"
  value       = var.enable_cross_region_backup ? aws_kms_key.cross_region_backup_key[0].arn : null
}

# Monitoring outputs
output "backup_log_group_name" {
  description = "Name of the backup CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_logs.name
}

output "backup_log_group_arn" {
  description = "ARN of the backup CloudWatch log group"
  value       = aws_cloudwatch_log_group.backup_logs.arn
}

output "backup_dashboard_name" {
  description = "Name of the backup monitoring dashboard"
  value       = aws_cloudwatch_dashboard.backup_dashboard.dashboard_name
}

output "backup_dashboard_url" {
  description = "URL to the backup monitoring dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.backup_dashboard.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the backup security alerts SNS topic"
  value       = var.create_sns_topic ? aws_sns_topic.backup_security_alerts[0].arn : null
}

# Security compliance outputs
output "vault_lock_enabled" {
  description = "Whether vault lock is enabled for compliance"
  value       = var.enable_vault_lock
}

output "encryption_enabled" {
  description = "Whether backup encryption is enabled"
  value       = true  # Always true in this secure configuration
}

output "cross_region_replication_enabled" {
  description = "Whether cross-region backup replication is enabled"
  value       = var.enable_cross_region_backup
}

output "backup_plan_names" {
  description = "Names of the backup plans created"
  value       = module.backup.plan_names
}

output "backup_plan_ids" {
  description = "IDs of the backup plans created"
  value       = module.backup.plan_ids
}
