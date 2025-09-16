#
# Outputs for restore testing example
#

# Backup vault information
output "vault_arn" {
  description = "ARN of the backup vault"
  value       = module.aws_backup.vault_arn
}

# Backup plans information
output "backup_plans" {
  description = "Created backup plans"
  value       = module.aws_backup.plans
}

# Restore testing plans information
output "restore_testing_plans" {
  description = "Created restore testing plans"
  value       = module.aws_backup.restore_testing_plans
}

# Restore testing selections information
output "restore_testing_selections" {
  description = "Created restore testing selections"
  value       = module.aws_backup.restore_testing_selections
}

# IAM role for restore testing
output "restore_testing_role_arn" {
  description = "ARN of the restore testing IAM role"
  value       = module.aws_backup.restore_testing_role_arn
}

# Test instance information
output "test_instance_id" {
  description = "ID of the test EC2 instance"
  value       = aws_instance.example.id
}

output "test_instance_arn" {
  description = "ARN of the test EC2 instance"
  value       = aws_instance.example.arn
}

# Restore testing summary
output "restore_testing_summary" {
  description = "Summary of restore testing configuration"
  value       = module.aws_backup.restore_testing_summary
}

# Next steps and useful information
output "next_steps" {
  description = "Next steps to verify the restore testing setup"
  value = {
    "1_verify_backup" = "Wait for the first backup to complete (runs daily at 2 AM UTC)"
    "2_check_plan"    = "Verify restore testing plan in AWS Console: ${try(module.aws_backup.restore_testing_plans.weekly_restore_test.console_url, "N/A")}"
    "3_monitor_tests" = "Monitor restore test executions every Sunday at 6 AM UTC"
    "4_review_logs"   = "Check CloudWatch logs at /aws/backup/restore-testing for detailed results"

    # CLI commands for verification
    cli_commands = {
      list_plans      = "aws backup list-restore-testing-plans"
      describe_plan   = try(module.aws_backup.restore_testing_plans.weekly_restore_test.cli_examples.describe_plan, "N/A")
      list_selections = try(module.aws_backup.restore_testing_plans.weekly_restore_test.cli_examples.list_selections, "N/A")
      manual_test     = "aws backup start-restore-testing-job --restore-testing-plan-name ${try(module.aws_backup.restore_testing_plans.weekly_restore_test.name, "N/A")}"
    }

    # Important notes
    notes = {
      "cost_optimization" = "Test instances use t3.nano to minimize costs during validation"
      "cleanup"           = "Restored test resources are automatically cleaned up after validation window"
      "monitoring"        = "Set up CloudWatch alarms for restore test failures if needed"
      "compliance"        = "This setup helps meet compliance requirements for backup validation"
    }
  }
}
