resource "aws_organizations_policy" "backup_policy" {
  count = var.enable_org_policy ? 1 : 0

  name        = var.org_policy_name
  description = var.org_policy_description
  type        = "BACKUP_POLICY"
  content = jsonencode({
    plans = {
      rules = {
        for rule_name, rule in var.backup_policies : rule_name => {
          target_backup_vault_name  = rule.target_vault_name
          schedule_expression       = rule.schedule
          start_window_minutes      = rule.start_window
          completion_window_minutes = rule.completion_window
          lifecycle = {
            delete_after_days               = rule.lifecycle.delete_after
            move_to_cold_storage_after_days = rule.lifecycle.cold_storage_after
          }
          recovery_point_tags      = rule.recovery_point_tags
          copy_actions             = rule.copy_actions
          enable_continuous_backup = rule.enable_continuous_backup
        }
      }
      selections = {
        for selection_name, selection in var.backup_selections : selection_name => {
          resources     = selection.resources
          not_resources = selection.not_resources
          conditions    = selection.conditions
          tags          = selection.tags
        }
      }
      advanced_backup_settings = var.advanced_backup_settings
      regions                  = var.backup_regions
    }
  })

  tags = var.tags
}

resource "aws_organizations_policy_attachment" "backup_policy" {
  count = var.enable_org_policy ? 1 : 0

  policy_id = aws_organizations_policy.backup_policy[0].id
  target_id = var.org_policy_target_id
}
