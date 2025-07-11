output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = module.backup_source.backup_plan_id
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.backup_source.backup_plan_arn
}

output "source_vault_arn" {
  description = "The ARN of the source backup vault"
  value       = module.backup_source.backup_vault_arn
}

output "destination_vault_arn" {
  description = "The ARN of the destination backup vault"
  value       = module.backup_destination.backup_vault_arn
}