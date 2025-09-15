output "vault_id" {
  description = "The name of the air gapped vault"
  value       = module.backup.vault_id
}

output "vault_arn" {
  description = "The ARN of the air gapped vault"
  value       = module.backup.vault_arn
}

output "vault_type" {
  description = "The type of vault created"
  value       = module.backup.vault_type
}

output "plan_id" {
  description = "The id of the backup plan"
  value       = module.backup.plan_id
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.backup.plan_arn
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = module.backup.plan_version
}
