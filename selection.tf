resource "aws_backup_selection" "ab_selection" {
  count = var.enabled && var.selection_name != null ? 1 : 0

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

  # Make sure the IAM role is ready before creating the selection
  depends_on = [
    aws_iam_role.ab_role,
    aws_iam_role_policy_attachment.ab_policy_attach,
    aws_iam_role_policy_attachment.ab_backup_s3_policy_attach,
    aws_iam_role_policy_attachment.ab_tag_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_policy_attach,
    aws_iam_role_policy_attachment.ab_restores_s3_policy_attach
  ]
}

locals {
  # Convert selections to map format
  selections_map = {
    for k, v in try(
      # If it's already a map, use it
      tomap(var.selections),
      # If it's a list, convert it to a map
      { for idx, selection in try(tolist(var.selections), []) :
        tostring(coalesce(try(selection.name, null), idx)) => selection
      }
    ) : k => v if var.enabled
  }
}

# Create additional selections from the selections variable
resource "aws_backup_selection" "ab_selections" {
  for_each = local.selections_map

  iam_role_arn = var.iam_role_arn == null ? aws_iam_role.ab_role[0].arn : var.iam_role_arn
  name         = each.key
  plan_id      = aws_backup_plan.ab_plan[0].id

  resources     = try(each.value.resources, [])
  not_resources = try(each.value.not_resources, [])

  dynamic "condition" {
    for_each = length(try(each.value["conditions"], {})) > 0 ? { "conditions" : each.value["conditions"] } : {}
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
    for_each = try(each.value.selection_tags, [])
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
