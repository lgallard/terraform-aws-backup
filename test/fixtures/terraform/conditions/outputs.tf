output "plan_arn" {
  description = "Backup plan ARN"
  value       = module.aws_backup_conditions.plan_arn
}

output "vault_arn" {
  description = "Backup vault ARN"
  value       = module.aws_backup_conditions.vault_arn
}

output "plan_id" {
  description = "Backup plan ID"
  value       = module.aws_backup_conditions.plan_id
}