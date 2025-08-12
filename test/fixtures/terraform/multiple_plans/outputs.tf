output "backup_plan_ids" {
  description = "The IDs of the backup plans"
  value       = module.backup.backup_plan_ids
}

output "backup_plan_arns" {
  description = "The ARNs of the backup plans"
  value       = module.backup.backup_plan_arns
}

output "backup_vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.backup_vault_arn
}
