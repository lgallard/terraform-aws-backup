resource "aws_backup_framework" "ab_framework" {
  count = var.audit_framework.create ? 1 : 0

  name        = var.audit_framework.name
  description = var.audit_framework.description

  dynamic "control" {
    for_each = var.audit_framework.controls
    content {
      name = control.value.name
      input_parameter {
        name  = control.value.parameter_name
        value = control.value.parameter_value
      }
    }
  }

  tags = var.tags
}

# Note: Framework policy assignment is not currently supported by the AWS provider
# You'll need to manage framework policy assignments through the AWS Console or AWS CLI
