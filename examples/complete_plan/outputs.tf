output "plan_id" {
  description = "The ID of the backup plan"
  value       = module.aws_backup_example.plan_id
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.aws_backup_example.plan_arn
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = module.aws_backup_example.plan_version
}

output "vault_id" {
  description = "The name of the vault"
  value       = module.aws_backup_example.vault_id
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = module.aws_backup_example.vault_arn
}
