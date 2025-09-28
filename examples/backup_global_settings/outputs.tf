# Global Settings Outputs
output "global_settings_id" {
  description = "AWS Account ID where global settings are applied"
  value       = module.aws_backup_global_settings.global_settings_id
}

output "global_settings" {
  description = "Configured global settings"
  value       = module.aws_backup_global_settings.global_settings
}

output "cross_account_backup_enabled" {
  description = "Whether cross-account backup is enabled"
  value       = module.aws_backup_global_settings.cross_account_backup_enabled
}

output "global_settings_summary" {
  description = "Summary of global settings configuration"
  value       = module.aws_backup_global_settings.global_settings_summary
}

# Additional backup outputs for reference
output "vault_arn" {
  description = "ARN of the backup vault"
  value       = module.aws_backup_global_settings.vault_arn
}

output "plan_arn" {
  description = "ARN of the backup plan"
  value       = module.aws_backup_global_settings.plan_arn
}