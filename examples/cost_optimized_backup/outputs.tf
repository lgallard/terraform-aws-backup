# Cost-Optimized Backup Outputs

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.cost_optimized_backup.backup_vault_arn
}

output "backup_vault_id" {
  description = "Name of the backup vault"
  value       = module.cost_optimized_backup.backup_vault_id
}

output "backup_plan_arns" {
  description = "ARNs of the backup plans by tier"
  value = {
    critical_tier    = module.cost_optimized_backup.backup_plan_arns["critical_tier"]
    standard_tier    = module.cost_optimized_backup.backup_plan_arns["standard_tier"]
    development_tier = module.cost_optimized_backup.backup_plan_arns["development_tier"]
  }
}

output "backup_plan_ids" {
  description = "IDs of the backup plans by tier"
  value = {
    critical_tier    = module.cost_optimized_backup.backup_plan_ids["critical_tier"]
    standard_tier    = module.cost_optimized_backup.backup_plan_ids["standard_tier"]
    development_tier = module.cost_optimized_backup.backup_plan_ids["development_tier"]
  }
}

output "backup_selection_ids" {
  description = "IDs of the backup selections by tier and resource type"
  value = {
    critical_resources    = module.cost_optimized_backup.backup_selection_ids["critical_tier-critical_resources"]
    standard_resources    = module.cost_optimized_backup.backup_selection_ids["standard_tier-standard_resources"]
    development_resources = module.cost_optimized_backup.backup_selection_ids["development_tier-development_resources"]
  }
}

output "iam_role_arn" {
  description = "ARN of the backup service IAM role"
  value       = module.cost_optimized_backup.backup_role_arn
}

output "cost_optimization_summary" {
  description = "Summary of cost optimization strategies implemented"
  value = {
    critical_tier = {
      frequency        = "Every 6 hours"
      cold_transition  = "1 day"
      retention_period = "30 days"
      estimated_cost   = "~$5/month per 100GB"
    }
    standard_tier = {
      frequency        = "Daily"
      cold_transition  = "30 days"
      retention_period = "90 days"
      estimated_cost   = "~$7/month per 100GB"
    }
    development_tier = {
      frequency        = "Weekly"
      cold_transition  = "None"
      retention_period = "7 days"
      estimated_cost   = "~$1/month per 100GB"
    }
    total_estimated_savings = "~60% compared to uniform daily backups"
  }
}
