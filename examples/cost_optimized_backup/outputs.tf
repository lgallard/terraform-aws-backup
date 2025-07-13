# Cost-Optimized Backup Outputs

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.cost_optimized_backup.vault_arn
}

output "backup_vault_id" {
  description = "Name of the backup vault"
  value       = module.cost_optimized_backup.vault_id
}

output "backup_plan_arns" {
  description = "ARNs of the backup plans by tier"
  value = {
    critical_tier    = module.cost_optimized_backup.plans["critical_tier"].arn
    standard_tier    = module.cost_optimized_backup.plans["standard_tier"].arn
    development_tier = module.cost_optimized_backup.plans["development_tier"].arn
  }
}

output "backup_plan_ids" {
  description = "IDs of the backup plans by tier"
  value = {
    critical_tier    = module.cost_optimized_backup.plans["critical_tier"].id
    standard_tier    = module.cost_optimized_backup.plans["standard_tier"].id
    development_tier = module.cost_optimized_backup.plans["development_tier"].id
  }
}

output "iam_role_arn" {
  description = "ARN of the backup service IAM role"
  value       = module.cost_optimized_backup.plan_role
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
