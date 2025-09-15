# Test fixture for restore testing functionality
module "aws_backup" {
  source = "../../../.."

  enabled    = true
  vault_name = var.vault_name

  # Basic backup plan
  plans = {
    test_plan = {
      name = var.plan_name
      rules = [
        {
          rule_name         = "daily_backups"
          target_vault_name = var.vault_name
          schedule          = "cron(0 2 ? * * *)"
          start_window      = 60
          completion_window = 300
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 90
          }
          enable_continuous_backup = false
        }
      ]
      selections = [
        {
          name      = var.selection_name
          resources = ["arn:aws:ec2:${var.aws_region}:*:instance/*"]
          conditions = {
            string_equals = [
              {
                key   = "aws:ResourceTag/Environment"
                value = "test"
              }
            ]
          }
        }
      ]
    }
  }

  # Restore testing plans
  restore_testing_plans = {
    test_restore_plan = {
      name                         = var.restore_testing_plan_name
      schedule_expression          = var.restore_testing_schedule
      schedule_expression_timezone = "UTC"
      start_window_hours           = 2

      recovery_point_selection = {
        algorithm             = "LATEST_WITHIN_WINDOW"
        include_vaults        = ["*"]
        recovery_point_types  = ["SNAPSHOT"]
        selection_window_days = 7
      }
    }
  }

  # Restore testing selections
  restore_testing_selections = {
    test_restore_selection = {
      name                      = var.restore_testing_selection_name
      restore_testing_plan_name = "test_restore_plan"
      protected_resource_type   = "EC2"
      validation_window_hours   = 24

      protected_resource_conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/Environment"
            value = "test"
          }
        ]
      }

      restore_metadata_overrides = {
        "InstanceType" = "t3.nano"
      }
    }
  }

  tags = {
    Environment = "test"
    CreatedBy   = "terratest"
  }
}