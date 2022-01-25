resource "aws_backup_selection" "ab_selection" {

  count = var.enabled ? length(local.selections) : 0

  iam_role_arn = var.iam_role_arn != null ? var.iam_role_arn : aws_iam_role.ab_role[0].arn
  name         = lookup(element(local.selections, count.index), "name", null)
  plan_id      = aws_backup_plan.ab_plan[0].id

  resources = lookup(element(local.selections, count.index), "resources", null)

  dynamic "selection_tag" {
    for_each = length(lookup(element(local.selections, count.index), "selection_tags", [])) == 0 ? [] : lookup(element(local.selections, count.index), "selection_tags", [])
    content {
      type  = lookup(selection_tag.value, "type", null)
      key   = lookup(selection_tag.value, "key", null)
      value = lookup(selection_tag.value, "value", null)
    }
  }

  not_resources = []
  condition {}
}

locals {

  # Selection
  selection = var.selection_name == null ? [] : [
    {
      name           = var.selection_name
      resources      = var.selection_resources
      selection_tags = var.selection_tags
    }
  ]

  # Selections
  selections = concat(local.selection, var.selections)

  # Make sure the role can get tag resources
  depends_on = [aws_iam_role_policy_attachment.ab_tag_policy_attach]


}
