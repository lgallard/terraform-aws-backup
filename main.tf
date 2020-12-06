# AWS Backup vault
resource "aws_backup_vault" "ab_vault" {
  count       = var.enabled && var.vault_name != null ? 1 : 0
  name        = var.vault_name
  kms_key_arn = var.vault_kms_key_arn
  tags        = var.tags
}

# AWS Backup plan
resource "aws_backup_plan" "ab_plan" {
  count = var.enabled ? 1 : 0
  name  = var.plan_name

  # Rules
  dynamic "rule" {
    for_each = local.rules
    content {
      rule_name           = lookup(rule.value, "name", null)
      target_vault_name   = lookup(rule.value, "target_vault_name", null) == null ? var.vault_name : lookup(rule.value, "target_vault_name", "Default")
      schedule            = lookup(rule.value, "schedule", null)
      start_window        = lookup(rule.value, "start_window", null)
      completion_window   = lookup(rule.value, "completion_window", null)
      recovery_point_tags = length(lookup(rule.value, "recovery_point_tags")) == 0 ? var.tags : lookup(rule.value, "recovery_point_tags")

      # Lifecycle  
      dynamic "lifecycle" {
        for_each = length(lookup(rule.value, "lifecycle")) == 0 ? [] : [lookup(rule.value, "lifecycle", {})]
        content {
          cold_storage_after = lookup(lifecycle.value, "cold_storage_after", 0)
          delete_after       = lookup(lifecycle.value, "delete_after", 90)
        }
      }

      # Copy action
      dynamic "copy_action" {
        for_each = length(lookup(rule.value, "copy_action", {})) == 0 ? [] : [lookup(rule.value, "copy_action", {})]
        content {
          destination_vault_arn = lookup(copy_action.value, "destination_vault_arn", null)

          # Copy Action Lifecycle
          dynamic "lifecycle" {
            for_each = length(lookup(copy_action.value, "lifecycle", {})) == 0 ? [] : [lookup(copy_action.value, "lifecycle", {})]
            content {
              cold_storage_after = lookup(lifecycle.value, "cold_storage_after", 0)
              delete_after       = lookup(lifecycle.value, "delete_after", 90)
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
      recovery_point_tags = var.rule_recovery_point_tags
    }
  ]

  # Rules
  rules = concat(local.rule, var.rules)

}
