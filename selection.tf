resource "aws_backup_selection" "ab_selection" {
  count = var.enabled && var.selection_name != null && length(var.plans) == 0 ? 1 : 0

  iam_role_arn = var.iam_role_arn == null ? aws_iam_role.ab_role[0].arn : var.iam_role_arn
  name         = var.selection_name
  plan_id      = aws_backup_plan.ab_plan[0].id

  resources     = var.selection_resources
  not_resources = var.selection_not_resources

  dynamic "condition" {
    for_each = length(try(var.selection_conditions, {})) > 0 ? { "conditions" : var.selection_conditions } : {}
    content {
      dynamic "string_equals" {
        for_each = try(condition.value["string_equals"], {})
        content {
          key   = string_equals.key
          value = string_equals.value
        }
      }
      dynamic "string_like" {
        for_each = try(condition.value["string_like"], {})
        content {
          key   = string_like.key
          value = string_like.value
        }
      }
      dynamic "string_not_equals" {
        for_each = try(condition.value["string_not_equals"], {})
        content {
          key   = string_not_equals.key
          value = string_not_equals.value
        }
      }
      dynamic "string_not_like" {
        for_each = try(condition.value["string_not_like"], {})
        content {
          key   = string_not_like.key
          value = string_not_like.value
        }
      }
    }
  }

  dynamic "selection_tag" {
    for_each = var.selection_tags
    content {
      type  = try(selection_tag.value.type, null)
      key   = try(selection_tag.value.key, null)
      value = try(selection_tag.value.value, null)
    }
  }

  # Optimized dependency management - use simplified dependencies
  depends_on = [
    aws_iam_role.ab_role,
    aws_iam_role_policy_attachment.ab_managed_policies,
    aws_iam_role_policy_attachment.ab_tag_policy_attach
  ]
}

locals {
  # Convert selections to map format for legacy method
  selections_map = {
    for k, v in try(
      # If it's already a map, use it
      tomap(var.selections),
      # If it's a list, convert it to a map
      { for idx, selection in try(tolist(var.selections), []) :
        tostring(coalesce(try(selection.name, null), idx)) => selection
      }
    ) : k => v if var.enabled && length(var.plans) == 0
  }

  # Create a flattened map of all plan selections with plan keys
  plan_selections = flatten([
    for plan_key, plan in var.plans : [
      for selection_key, selection in plan.selections : {
        plan_key      = plan_key
        selection_key = selection_key
        selection     = selection
      }
    ]
  ])

  # Convert to map with unique keys for for_each
  plan_selections_map = {
    for item in local.plan_selections : "${item.plan_key}-${item.selection_key}" => item
  }
}

# Create additional selections from the selections variable (legacy method)
resource "aws_backup_selection" "ab_selections" {
  for_each = local.selections_map

  iam_role_arn = var.iam_role_arn == null ? aws_iam_role.ab_role[0].arn : var.iam_role_arn
  name         = each.key
  plan_id      = aws_backup_plan.ab_plan[0].id

  resources     = try(each.value.resources, [])
  not_resources = try(each.value.not_resources, [])

  dynamic "condition" {
    for_each = length(coalesce(try(each.value["conditions"], null), {})) > 0 ? { "conditions" : coalesce(try(each.value["conditions"], null), {}) } : {}
    content {
      dynamic "string_equals" {
        for_each = try(condition.value["string_equals"], {})
        content {
          key   = string_equals.key
          value = string_equals.value
        }
      }
      dynamic "string_like" {
        for_each = try(condition.value["string_like"], {})
        content {
          key   = string_like.key
          value = string_like.value
        }
      }
      dynamic "string_not_equals" {
        for_each = try(condition.value["string_not_equals"], {})
        content {
          key   = string_not_equals.key
          value = string_not_equals.value
        }
      }
      dynamic "string_not_like" {
        for_each = try(condition.value["string_not_like"], {})
        content {
          key   = string_not_like.key
          value = string_not_like.value
        }
      }
    }
  }

  dynamic "selection_tag" {
    for_each = coalesce(try(each.value.selection_tags, null), [])
    content {
      type  = try(selection_tag.value.type, null)
      key   = try(selection_tag.value.key, null)
      value = try(selection_tag.value.value, null)
    }
  }

  depends_on = [
    aws_iam_role.ab_role,
    aws_iam_role_policy_attachment.ab_policy_attach,
    aws_iam_role_policy_attachment.ab_backup_s3_policy_attach,
    aws_iam_role_policy_attachment.ab_tag_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_s3_policy_attach
  ]
}

# Create selections for multiple plans
resource "aws_backup_selection" "plan_selections" {
  for_each = var.enabled ? local.plan_selections_map : {}

  iam_role_arn = var.iam_role_arn == null ? aws_iam_role.ab_role[0].arn : var.iam_role_arn
  name         = each.value.selection_key
  plan_id      = aws_backup_plan.ab_plans[each.value.plan_key].id

  resources     = try(each.value.selection.resources, [])
  not_resources = try(each.value.selection.not_resources, [])

  dynamic "condition" {
    for_each = length(coalesce(try(each.value.selection["conditions"], null), {})) > 0 ? { "conditions" : coalesce(try(each.value.selection["conditions"], null), {}) } : {}
    content {
      dynamic "string_equals" {
        for_each = try(condition.value["string_equals"], {})
        content {
          key   = string_equals.key
          value = string_equals.value
        }
      }
      dynamic "string_like" {
        for_each = try(condition.value["string_like"], {})
        content {
          key   = string_like.key
          value = string_like.value
        }
      }
      dynamic "string_not_equals" {
        for_each = try(condition.value["string_not_equals"], {})
        content {
          key   = string_not_equals.key
          value = string_not_equals.value
        }
      }
      dynamic "string_not_like" {
        for_each = try(condition.value["string_not_like"], {})
        content {
          key   = string_not_like.key
          value = string_not_like.value
        }
      }
    }
  }

  dynamic "selection_tag" {
    for_each = coalesce(try(each.value.selection.selection_tags, null), [])
    content {
      type  = try(selection_tag.value.type, null)
      key   = try(selection_tag.value.key, null)
      value = try(selection_tag.value.value, null)
    }
  }

  depends_on = [
    aws_iam_role.ab_role,
    aws_iam_role_policy_attachment.ab_policy_attach,
    aws_iam_role_policy_attachment.ab_backup_s3_policy_attach,
    aws_iam_role_policy_attachment.ab_tag_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_s3_policy_attach
  ]
}
