resource "aws_backup_selection" "ab_selection" {

  count = var.enabled ? length(local.selections) : 0

  iam_role_arn = aws_iam_role.ab_role[0].arn
  name         = lookup(element(local.selections, count.index), "name", null)
  plan_id      = aws_backup_plan.ab_plan[0].id

  resources = lookup(element(local.selections, count.index), "resources", null)

  dynamic "selection_tag" {
    for_each = length(lookup(element(local.selections, count.index), "selection_tag", {})) == 0 ? [] : [lookup(element(local.selections, count.index), "selection_tag", {})]
    content {
      type  = lookup(selection_tag.value, "type", null)
      key   = lookup(selection_tag.value, "key", null)
      value = lookup(selection_tag.value, "value", null)
    }
  }
}

locals {

  # Selection
  selection = var.selection_name == null ? [] : [
    {
      name      = var.selection_name
      resources = var.selection_resources
      selection_tag = var.selection_tag_type == null ? {} : {
        type  = var.selection_tag_type
        key   = var.selection_tag_key
        value = var.selection_tag_value
      }
    }
  ]

  # Selections
  selections = concat(local.selection, var.selections)

  # Make sure the role can get tag resources
  depends_on = [aws_iam_role_policy_attachment.ab_tag_policy_attach]


}
