
# Optimized locals for better maintainability and performance
locals {
  # Resource creation conditions (pre-computed for efficiency)
  should_create_vault       = var.enabled && var.vault_name != null
  should_create_lock        = local.should_create_vault && var.locked
  should_create_legacy_plan = var.enabled && length(var.plans) == 0 && length(local.processed_rules) > 0

  # Validation helpers for vault lock configuration
  vault_lock_requirements_met = var.min_retention_days != null && var.max_retention_days != null
  retention_days_valid        = local.vault_lock_requirements_met ? var.min_retention_days <= var.max_retention_days : true
  check_retention_days        = var.locked ? (local.vault_lock_requirements_met && local.retention_days_valid) : true

  # Optimized rule processing with pre-validation and normalization
  rule = var.rule_name == null ? [] : [{
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
  }]

  raw_rules = concat(local.rule, var.rules)
  
  # Pre-process rules with validation and normalization (cache expensive computations)
  processed_rules = [
    for rule in local.raw_rules : merge(rule, {
      # Normalize lifecycle configuration
      normalized_lifecycle = try(rule.lifecycle, null) != null ? {
        cold_storage_after = max(0, try(rule.lifecycle.cold_storage_after, var.default_lifecycle_cold_storage_after_days))
        delete_after       = max(1, try(rule.lifecycle.delete_after, var.default_lifecycle_delete_after_days))
      } : null
      
      # Pre-validate and normalize copy actions
      validated_copy_actions = [
        for copy_action in try(rule.copy_actions, []) : merge(copy_action, {
          normalized_lifecycle = try(copy_action.lifecycle, null) != null ? {
            cold_storage_after = max(0, try(copy_action.lifecycle.cold_storage_after, var.default_lifecycle_cold_storage_after_days))
            delete_after       = max(1, try(copy_action.lifecycle.delete_after, var.default_lifecycle_delete_after_days))
          } : null
        })
      ]
    })
  ]
  
  # Maintain backwards compatibility
  rules = local.processed_rules

  # Selection processing (comprehensive logic for VSS validation)
  selection_resources = flatten([
    # Legacy single selection
    var.selection_resources,
    # Legacy multiple selections (var.selections)
    [for selection in try(tolist(var.selections), []) : try(selection.resources, [])],
    [for k, selection in try(tomap(var.selections), {}) : try(selection.resources, [])],
    # New multiple selections (var.backup_selections)
    [for selection in var.backup_selections : try(selection.resources, [])],
    # Plan-based selections
    [for plan in var.plans : flatten([for selection in try(plan.selections, []) : try(selection.resources, [])])]
  ])

  # Plans processing
  plans_map = var.plans

  # Optimized lifecycle validations (single pass with pre-processed rules)
  lifecycle_validations = alltrue([
    for rule in local.processed_rules : (
      rule.normalized_lifecycle == null || 
      rule.normalized_lifecycle.cold_storage_after <= rule.normalized_lifecycle.delete_after
    ) &&
    alltrue([
      for copy_action in rule.validated_copy_actions : (
        copy_action.normalized_lifecycle == null ||
        copy_action.normalized_lifecycle.cold_storage_after <= copy_action.normalized_lifecycle.delete_after
      )
    ])
  ])
}

# AWS Backup vault with optimized timeouts
resource "aws_backup_vault" "ab_vault" {
  count = local.should_create_vault ? 1 : 0

  name          = var.vault_name
  kms_key_arn   = var.vault_kms_key_arn
  force_destroy = var.vault_force_destroy
  tags          = var.tags
  
  timeouts {
    create = "10m"
    delete = "10m"
  }
}

# AWS Backup vault lock configuration
resource "aws_backup_vault_lock_configuration" "ab_vault_lock_configuration" {
  count = local.should_create_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.ab_vault[0].name
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
  changeable_for_days = var.changeable_for_days

  lifecycle {
    precondition {
      condition     = local.check_retention_days
      error_message = "When vault locking is enabled (locked = true), min_retention_days and max_retention_days must be provided and min_retention_days must be less than or equal to max_retention_days."
    }
  }
}

# Legacy AWS Backup plan (for backward compatibility) with optimized timeouts
resource "aws_backup_plan" "ab_plan" {
  count = local.should_create_legacy_plan ? 1 : 0
  name  = coalesce(var.plan_name, "aws-backup-plan-${var.vault_name != null ? var.vault_name : "default"}")
  
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

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
      recovery_point_tags      = coalesce(rule.value.recovery_point_tags, var.tags)

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(try(rule.value.lifecycle, {})) == 0 ? [] : [rule.value.lifecycle]
        content {
          cold_storage_after = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
          delete_after       = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
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
              cold_storage_after = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
              delete_after       = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
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
      condition     = !var.windows_vss_backup || (length(local.selection_resources) > 0 && can(regex("(?i).*ec2.*", join(",", local.selection_resources))))
      error_message = "Windows VSS backup is enabled but no EC2 instances are selected for backup. Either disable windows_vss_backup or include EC2 instances in your backup selection."
    }

    # Add lifecycle validations at the plan level
    precondition {
      condition     = local.lifecycle_validations
      error_message = "In one or more rules, cold_storage_after must be less than or equal to delete_after."
    }
  }
}

# Multiple AWS Backup plans with optimized timeouts
resource "aws_backup_plan" "ab_plans" {
  for_each = var.enabled ? local.plans_map : {}
  name     = coalesce(each.value.name, each.key)
  
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }

  # Rules
  dynamic "rule" {
    for_each = each.value.rules
    content {
      rule_name                = try(rule.value.name, null)
      target_vault_name        = try(rule.value.target_vault_name, null) != null ? rule.value.target_vault_name : var.vault_name != null ? aws_backup_vault.ab_vault[0].name : "Default"
      schedule                 = try(rule.value.schedule, null)
      start_window             = try(rule.value.start_window, null)
      completion_window        = try(rule.value.completion_window, null)
      enable_continuous_backup = try(rule.value.enable_continuous_backup, null)
      recovery_point_tags      = coalesce(rule.value.recovery_point_tags, var.tags)

      # Lifecycle
      dynamic "lifecycle" {
        for_each = length(try(rule.value.lifecycle, {})) == 0 ? [] : [rule.value.lifecycle]
        content {
          cold_storage_after = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
          delete_after       = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
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
              cold_storage_after = try(lifecycle.value.cold_storage_after, var.default_lifecycle_cold_storage_after_days)
              delete_after       = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)
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
      condition     = !var.windows_vss_backup || (length(local.selection_resources) > 0 && can(regex("(?i).*ec2.*", join(",", local.selection_resources))))
      error_message = "Windows VSS backup is enabled but no EC2 instances are selected for backup. Either disable windows_vss_backup or include EC2 instances in your backup selection."
    }
  }
}

