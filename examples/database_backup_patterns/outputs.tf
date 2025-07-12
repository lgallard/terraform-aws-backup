# Database Backup Patterns Outputs

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = module.database_backup_patterns.backup_vault_name
}

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.database_backup_patterns.backup_vault_arn
}

output "backup_plans" {
  description = "Map of backup plan details"
  value = {
    for plan_name in keys(module.database_backup_patterns.backup_plan_names) :
    plan_name => {
      name = module.database_backup_patterns.backup_plan_names[plan_name]
      arn  = module.database_backup_patterns.backup_plan_arns[plan_name]
    }
  }
}

output "backup_selections" {
  description = "Map of backup selection details"
  value = {
    for selection_name in keys(module.database_backup_patterns.backup_selection_names) :
    selection_name => {
      name = module.database_backup_patterns.backup_selection_names[selection_name]
    }
  }
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for backups"
  value       = module.database_backup_patterns.backup_role_arn
}

output "monitoring_alarm_arn" {
  description = "ARN of the backup failure CloudWatch alarm"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.backup_failure_alarm[0].arn : null
}

output "backup_validator_function_arn" {
  description = "ARN of the backup validation Lambda function"
  value       = var.enable_backup_validation ? aws_lambda_function.backup_validator[0].arn : null
}

output "backup_strategy_summary" {
  description = "Summary of backup strategies implemented"
  value = {
    critical_databases = {
      frequency        = "Every 6 hours"
      retention_days   = var.critical_retention_days
      continuous_backup = true
      cold_storage_days = var.enable_cold_storage ? 7 : null
    }
    standard_databases = {
      frequency        = "Daily at 3 AM"
      retention_days   = var.standard_retention_days
      continuous_backup = false
      cold_storage_days = var.enable_cold_storage ? var.cold_storage_after_days : null
    }
    development_databases = {
      frequency        = "Weekly on Sunday"
      retention_days   = var.development_retention_days
      continuous_backup = false
      cold_storage_days = null
    }
    dynamodb_backup = {
      frequency        = "Daily at 4 AM"
      retention_days   = 365
      continuous_backup = false
      cold_storage_days = var.enable_cold_storage ? 90 : null
    }
  }
}