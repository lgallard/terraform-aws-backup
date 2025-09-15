# Vault
output "vault_id" {
  description = "The name of the vault"
  value       = var.vault_type == "standard" ? try(aws_backup_vault.ab_vault[0].id, null) : try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].id, null)
}

output "vault_arn" {
  description = "The ARN of the vault"
  value       = var.vault_type == "standard" ? try(aws_backup_vault.ab_vault[0].arn, null) : try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].arn, null)
}

output "vault_type" {
  description = "The type of vault created"
  value       = var.vault_type
}

# Air Gapped Vault specific outputs
output "airgapped_vault_id" {
  description = "The name of the air gapped vault"
  value       = try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].id, null)
}

output "airgapped_vault_arn" {
  description = "The ARN of the air gapped vault"
  value       = try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].arn, null)
}

# Note: recovery_points attribute may not be available in all provider versions
# output "airgapped_vault_recovery_points" {
#   description = "The number of recovery points stored in the air gapped vault (sensitive for security)"
#   value       = try(aws_backup_logically_air_gapped_vault.ab_airgapped_vault[0].recovery_points, null)
#   sensitive   = true
# }

# Legacy Plan
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

# Multiple Plans
output "plans" {
  description = "Map of plans created and their attributes"
  value = {
    for k, v in aws_backup_plan.ab_plans : k => {
      id      = v.id
      arn     = v.arn
      version = v.version
      name    = v.name
    }
  }
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

#
# Restore Testing Plans
#
output "restore_testing_plans" {
  description = "Map of restore testing plans created and their attributes"
  value = {
    for k, v in aws_backup_restore_testing_plan.this : k => {
      arn                          = v.arn
      name                         = v.name
      schedule_expression          = v.schedule_expression
      schedule_expression_timezone = v.schedule_expression_timezone
      start_window_hours           = v.start_window_hours
      recovery_point_selection     = v.recovery_point_selection

      # Actionable URLs for operations
      console_url = "https://console.aws.amazon.com/backup/home?region=${data.aws_partition.current.dns_suffix == "amazonaws.com" ? "us-east-1" : "us-gov-east-1"}#/restoretesting/plans/${v.name}"

      # CLI examples for common operations
      cli_examples = {
        describe_plan   = "aws backup describe-restore-testing-plan --restore-testing-plan-name ${v.name}"
        list_selections = "aws backup list-restore-testing-selections --restore-testing-plan-name ${v.name}"
        start_test      = "aws backup start-restore-testing-job --restore-testing-plan-name ${v.name}"
      }
    }
  }
}

#
# Restore Testing Selections
#
output "restore_testing_selections" {
  description = "Map of restore testing selections created and their attributes"
  value = {
    for k, v in aws_backup_restore_testing_selection.this : k => {
      name                          = v.name
      restore_testing_plan_name     = v.restore_testing_plan_name
      protected_resource_type       = v.protected_resource_type
      iam_role_arn                  = v.iam_role_arn
      protected_resource_arns       = v.protected_resource_arns
      protected_resource_conditions = v.protected_resource_conditions
      restore_metadata_overrides    = v.restore_metadata_overrides
      validation_window_hours       = v.validation_window_hours

      # Actionable URLs and CLI examples
      console_url = "https://console.aws.amazon.com/backup/home?region=${data.aws_partition.current.dns_suffix == "amazonaws.com" ? "us-east-1" : "us-gov-east-1"}#/restoretesting/plans/${v.restore_testing_plan_name}/selections/${v.name}"

      cli_examples = {
        describe_selection = "aws backup describe-restore-testing-selection --restore-testing-plan-name ${v.restore_testing_plan_name} --restore-testing-selection-name ${v.name}"
        start_validation   = "aws backup start-restore-testing-job --restore-testing-plan-name ${v.restore_testing_plan_name} --restore-testing-selection-name ${v.name}"
      }
    }
  }
}

#
# Restore Testing IAM Role
#
output "restore_testing_role_arn" {
  description = "The ARN of the restore testing IAM role"
  value       = var.restore_testing_iam_role_arn == null ? try(aws_iam_role.restore_testing_role[0].arn, null) : var.restore_testing_iam_role_arn
}

output "restore_testing_role_name" {
  description = "The name of the restore testing IAM role"
  value       = var.restore_testing_iam_role_arn == null ? try(aws_iam_role.restore_testing_role[0].name, null) : null
}

#
# Restore Testing Summary
#
output "restore_testing_summary" {
  description = "Summary of restore testing configuration and quick reference"
  value = length(aws_backup_restore_testing_plan.this) > 0 ? {
    plans_count      = length(aws_backup_restore_testing_plan.this)
    selections_count = length(aws_backup_restore_testing_selection.this)
    iam_role_created = local.create_restore_testing_iam_resources

    # Quick reference for next steps
    next_steps = {
      "1" = "Monitor restore test executions in AWS Console"
      "2" = "Review CloudWatch logs for detailed test results"
      "3" = "Set up SNS notifications for test completion alerts"
      "4" = "Consider adding more resource types to testing selections"
    }

    # Monitoring and troubleshooting
    monitoring = {
      cloudwatch_log_group = "/aws/backup/restore-testing"
      console_link         = "https://console.aws.amazon.com/backup/home#/restoretesting"

      common_cli_commands = {
        list_all_plans   = "aws backup list-restore-testing-plans"
        list_recent_jobs = "aws backup list-restore-jobs --by-creation-date-after $(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%SZ)"
        describe_job     = "aws backup describe-restore-job --restore-job-id JOB_ID"
      }
    }
  } : null
}
