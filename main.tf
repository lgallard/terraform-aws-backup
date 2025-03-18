# AWS Backup vault
resource "aws_backup_vault" "ab_vault" {
  count = var.enabled && var.vault_name != null ? 1 : 0

  name          = var.vault_name
  kms_key_arn   = var.vault_kms_key_arn
  force_destroy = var.vault_force_destroy
  tags          = var.tags
}

# AWS Backup vault lock configuration
resource "aws_backup_vault_lock_configuration" "ab_vault_lock_configuration" {
  count = var.locked && var.vault_name != null ? 1 : 0

  backup_vault_name   = aws_backup_vault.ab_vault[0].name
  changeable_for_days = var.changeable_for_days
  max_retention_days  = var.max_retention_days
  min_retention_days  = var.min_retention_days

  lifecycle {
    precondition {
      condition     = var.min_retention_days != null && var.max_retention_days != null && var.min_retention_days <= var.max_retention_days
      error_message = "For vault lock configuration, min_retention_days and max_retention_days must be provided and min_retention_days must be less than or equal to max_retention_days."
    }
  }
}

# AWS Backup plan
resource "aws_backup_plan" "ab_plan" {
  count = var.enabled && length(local.rules) > 0 ? 1 : 0
  name  = coalesce(var.plan_name, "aws-backup-plan-${var.vault_name != null ? var.vault_name : "default"}")

  # Rules
  dynamic "rule" {
    for_each = local.rules
    content {
      rule_name                = try(rule.value.name, null)
      target_vault_name        = try(rule.value.target_vault_name, null) != null ? rule.value.target_vault_name : var.vault_name != null ? aws_backup_vault.ab_vault[0].name : "Default"
      schedule                 = try(rule.value.schedule, null)
      start_window             = try(rule.value.start_window, null)
      completion_window        = try(rule.value.completion_window, null)
      enable_continuous_backup = try(rule.value.enable_continuous_backup, null)
      recovery_point_tags      = length(try(rule.value.recovery_point_tags, {})) == 0 ? var.tags : rule.value.recovery_point_tags

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(try(rule.value.lifecycle, {})) == 0 ? [] : [rule.value.lifecycle]
        content {
          cold_storage_after = try(lifecycle.value.cold_storage_after, 0)
          delete_after       = try(lifecycle.value.delete_after, 90)
        }
      }

      # Copy action
      dynamic "copy_action" {
        for_each = try(rule.value.copy_actions, [])
        content {
          destination_vault_arn = try(copy_action.value.destination_vault_arn, null)

          # Copy Action Lifecycle
          dynamic "lifecycle" {
            for_each = length(try(copy_action.value.lifecycle, {})) == 0 ? [] : [copy_action.value.lifecycle]
            content {
              cold_storage_after = try(lifecycle.value.cold_storage_after, 0)
              delete_after       = try(lifecycle.value.delete_after, 90)
            }
          }
        }
      }
    }
  }

  # Advanced backup setting
  dynamic "advanced_backup_setting" {
    for_each = var.windows_vss_backup ? [1] : []
    content {
      backup_options = {
        WindowsVSS = "enabled"
      }
      resource_type = "EC2"
    }
  }

  # Tags
  tags = var.tags

  # First create the vault if needed
  depends_on = [aws_backup_vault.ab_vault]

  lifecycle {
    precondition {
      condition     = !var.windows_vss_backup || can(regex(".*EC2.*", join(",", local.selection_resources)))
      error_message = "Windows VSS backup is enabled but no EC2 instances are selected for backup."
    }

    # Add lifecycle validations at the plan level
    precondition {
      condition     = local.lifecycle_validations
      error_message = "In one or more rules, cold_storage_after must be less than or equal to delete_after."
    }
  }
}

locals {
  # Rule
  rule = var.rule_name == null ? [] : [
    {
      name              = var.rule_name
      target_vault_name = var.vault_name != null ? var.vault_name : "Default"
      schedule          = var.rule_schedule
      start_window      = var.rule_start_window
      completion_window = var.rule_completion_window
      lifecycle = var.rule_lifecycle_cold_storage_after == null ? {} : {
        cold_storage_after = var.rule_lifecycle_cold_storage_after
        delete_after       = var.rule_lifecycle_delete_after
      }
      enable_continuous_backup = var.rule_enable_continuous_backup
      recovery_point_tags      = var.rule_recovery_point_tags
    }
  ]

  # Rules
  rules = concat(local.rule, var.rules)

  # Helper for VSS validation
  selection_resources = flatten([
    for selection in var.backup_selections : try(selection.resources, [])
  ])

  # Lifecycle validations
  lifecycle_validations = alltrue([
    for rule in local.rules : (
      length(try(rule.lifecycle, {})) == 0 ? true :
      try(rule.lifecycle.cold_storage_after, 0) <= try(rule.lifecycle.delete_after, 90)
    ) &&
    alltrue([
      for copy_action in try(rule.copy_actions, []) : (
        length(try(copy_action.lifecycle, {})) == 0 ? true :
        try(copy_action.lifecycle.cold_storage_after, 0) <= try(copy_action.lifecycle.delete_after, 90)
      )
    ])
  ])
}
