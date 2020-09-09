# Vault
output "vault_id" {
  description = "The name of the vault"
  value       = join("", aws_backup_vault.ab_vault.*.id)
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = join("", aws_backup_vault.ab_vault.*.arn)
}

# Plan
output "plan_id" {
  description = "The id of the backup plan"
  value       = join("", aws_backup_plan.ab_plan.*.id)
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = join("", aws_backup_plan.ab_plan.*.arn)
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = join("", aws_backup_plan.ab_plan.*.version)
}

output "plan_role" {
  description = "The service role of the backup plan"
  value       = join("", aws_iam_role.ab_role.*.name)
}
