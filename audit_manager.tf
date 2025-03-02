locals {
  # Process controls to handle null/empty parameters correctly
  framework_controls = [
    for control in var.audit_framework.controls : {
      name = control.name
      # Only create parameters if both name and value are non-null and non-empty
      parameters = (control.parameter_name == null || control.parameter_name == "" ||
        control.parameter_value == null || control.parameter_value == "") ? [] : [
        {
          name  = control.parameter_name
          value = control.parameter_value
        }
      ]
    }
  ]
}

resource "aws_backup_framework" "ab_framework" {
  count = var.audit_framework.create ? 1 : 0

  name        = var.audit_framework.name
  description = var.audit_framework.description

  dynamic "control" {
    for_each = local.framework_controls
    content {
      name = control.value.name

      # Only create input_parameter block if parameters exist
      dynamic "input_parameter" {
        for_each = control.value.parameters
        content {
          name  = input_parameter.value.name
          value = input_parameter.value.value
        }
      }
    }
  }

  # Only add tags if they are provided
  tags = var.tags

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

# Note: Framework policy assignment is not currently supported by the AWS provider
# You'll need to manage framework policy assignments through the AWS Console or AWS CLI
