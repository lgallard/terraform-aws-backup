output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = module.backup.plan_id
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.backup.plan_arn
}

output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = module.backup.vault_id
}

output "backup_vault_arn" {
  description = "The ARN of the backup vault"
  value       = module.backup.vault_arn
}

output "backup_role_arn" {
  description = "The ARN of the backup role"
  value       = module.backup.plan_role
}