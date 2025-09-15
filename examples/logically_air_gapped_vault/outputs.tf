#
# Outputs for Simple Backup plan with Logically Air Gapped Vault
#

output "vault_id" {
  description = "The name of the air gapped vault"
  value       = module.aws_backup_plan.vault_id
}

output "vault_arn" {
  description = "The ARN of the air gapped vault"
  value       = module.aws_backup_plan.vault_arn
}

output "vault_type" {
  description = "The type of vault created"
  value       = module.aws_backup_plan.vault_type
}

output "airgapped_vault_id" {
  description = "The name of the air gapped vault (specific output)"
  value       = module.aws_backup_plan.airgapped_vault_id
}

output "airgapped_vault_arn" {
  description = "The ARN of the air gapped vault (specific output)"
  value       = module.aws_backup_plan.airgapped_vault_arn
}

# Note: recovery_points attribute may not be available in all provider versions
# output "airgapped_vault_recovery_points" {
#   description = "The number of recovery points stored in the air gapped vault (sensitive for security)"
#   value       = module.aws_backup_plan.airgapped_vault_recovery_points
#   sensitive   = true
# }

output "plan_id" {
  description = "The id of the backup plan"
  value       = module.aws_backup_plan.plan_id
}

output "plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.aws_backup_plan.plan_arn
}

output "plan_version" {
  description = "Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan"
  value       = module.aws_backup_plan.plan_version
}

output "plan_role" {
  description = "The service role of the backup plan"
  value       = module.aws_backup_plan.plan_role
}
