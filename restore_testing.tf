#
# AWS Backup Restore Testing Plans
#

# Organized locals for restore testing resource management
locals {
  # Resource creation conditions
  should_create_restore_testing_plans      = var.enabled && length(var.restore_testing_plans) > 0
  should_create_restore_testing_selections = var.enabled && length(var.restore_testing_selections) > 0

  # IAM role determination for restore testing selections
  restore_testing_iam_role_arn = var.restore_testing_iam_role_arn != null ? var.restore_testing_iam_role_arn : (
    local.create_restore_testing_iam_resources ? aws_iam_role.restore_testing_role[0].arn : null
  )

}

# AWS Backup Restore Testing Plan
resource "aws_backup_restore_testing_plan" "this" {
  for_each = local.should_create_restore_testing_plans ? var.restore_testing_plans : {}

  name                         = each.value.name
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.schedule_expression_timezone
  start_window_hours           = each.value.start_window_hours

  recovery_point_selection {
    algorithm             = each.value.recovery_point_selection.algorithm
    include_vaults        = each.value.recovery_point_selection.include_vaults
    recovery_point_types  = each.value.recovery_point_selection.recovery_point_types
    exclude_vaults        = each.value.recovery_point_selection.exclude_vaults
    selection_window_days = each.value.recovery_point_selection.selection_window_days
  }

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )

  depends_on = [
    aws_backup_vault.ab_vault
  ]
}

# AWS Backup Restore Testing Selection
resource "aws_backup_restore_testing_selection" "this" {
  for_each = local.should_create_restore_testing_selections ? var.restore_testing_selections : {}

  name                      = each.value.name
  restore_testing_plan_name = aws_backup_restore_testing_plan.this[each.value.restore_testing_plan_name].name
  protected_resource_type   = each.value.protected_resource_type
  iam_role_arn              = each.value.iam_role_arn != null ? each.value.iam_role_arn : local.restore_testing_iam_role_arn

  protected_resource_arns    = each.value.protected_resource_arns
  restore_metadata_overrides = each.value.restore_metadata_overrides
  validation_window_hours    = each.value.validation_window_hours

  # Protected resource conditions (optional)
  dynamic "protected_resource_conditions" {
    for_each = each.value.protected_resource_conditions != null ? [each.value.protected_resource_conditions] : []

    content {
      dynamic "string_equals" {
        for_each = protected_resource_conditions.value.string_equals != null ? protected_resource_conditions.value.string_equals : []

        content {
          key   = string_equals.value.key
          value = string_equals.value.value
        }
      }

      dynamic "string_not_equals" {
        for_each = protected_resource_conditions.value.string_not_equals != null ? protected_resource_conditions.value.string_not_equals : []

        content {
          key   = string_not_equals.value.key
          value = string_not_equals.value.value
        }
      }
    }
  }

  depends_on = [
    aws_backup_restore_testing_plan.this,
    aws_iam_role.restore_testing_role
  ]
}