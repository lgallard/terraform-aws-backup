output "vault_arn" {
  value = module.aws_backup.vault_arn
}

output "vault_id" {
  value = module.aws_backup.vault_id
}

output "plans" {
  value = module.aws_backup.plans
}

output "restore_testing_plans" {
  value = module.aws_backup.restore_testing_plans
}

output "restore_testing_selections" {
  value = module.aws_backup.restore_testing_selections
}

output "restore_testing_role_arn" {
  value = module.aws_backup.restore_testing_role_arn
}

output "restore_testing_role_name" {
  value = module.aws_backup.restore_testing_role_name
}

output "restore_testing_summary" {
  value = module.aws_backup.restore_testing_summary
}
