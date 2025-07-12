# Cross-Region Backup Outputs

output "primary_vault_name" {
  description = "Name of the primary backup vault"
  value       = module.cross_region_backup.backup_vault_name
}

output "primary_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = module.cross_region_backup.backup_vault_arn
}

output "secondary_vault_name" {
  description = "Name of the secondary backup vault"
  value       = aws_backup_vault.secondary_vault.name
}

output "secondary_vault_arn" {
  description = "ARN of the secondary backup vault"
  value       = aws_backup_vault.secondary_vault.arn
}

output "backup_plan_name" {
  description = "Name of the backup plan"
  value       = module.cross_region_backup.backup_plan_name
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = module.cross_region_backup.backup_plan_arn
}

output "backup_selection_name" {
  description = "Name of the backup selection"
  value       = module.cross_region_backup.backup_selection_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for backups"
  value       = module.cross_region_backup.backup_role_arn
}