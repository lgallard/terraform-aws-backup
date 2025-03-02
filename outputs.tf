# Vault
output "vault_id" {
  description = "The name of the vault"
  value       = try(aws_backup_vault.ab_vault[0].id, null)
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = try(aws_backup_vault.ab_vault[0].arn, null)
}

# Plan
output "plan_id" {
  description = "The id of the backup plan"
  value       = try(aws_backup_plan.ab_plan[0].id, null)
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = try(aws_backup_plan.ab_plan[0].arn, null)
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = try(aws_backup_plan.ab_plan[0].version, null)
}

output "plan_role" {
  description = "The service role of the backup plan"
  value       = var.iam_role_arn == null ? try(aws_iam_role.ab_role[0].arn, null) : var.iam_role_arn
}

# Framework
output "framework_arn" {
  description = "The ARN of the backup framework"
  value       = try(aws_backup_framework.ab_framework[0].arn, null)
}

output "framework_id" {
  description = "The unique identifier of the backup framework"
  value       = try(aws_backup_framework.ab_framework[0].id, null)
}

output "framework_status" {
  description = "The deployment status of the backup framework"
  value       = try(aws_backup_framework.ab_framework[0].status, null)
}

output "framework_creation_time" {
  description = "The date and time that the backup framework was created"
  value       = try(aws_backup_framework.ab_framework[0].creation_time, null)
}
