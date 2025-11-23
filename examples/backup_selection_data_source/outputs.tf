# Backup Selection Data Source Outputs

output "backup_plan_id" {
  description = "ID of the created backup plan (use this with data source)"
  value       = module.backup_with_selections.plans["production"].id
}

output "backup_plan_arn" {
  description = "ARN of the created backup plan"
  value       = module.backup_with_selections.plans["production"].arn
}

output "backup_plan_name" {
  description = "Name of the created backup plan"
  value       = module.backup_with_selections.plans["production"].name
}

# Example outputs if using the data source (uncomment when configured):
#
# output "ec2_selection_name" {
#   description = "Name of the EC2 backup selection"
#   value       = data.aws_backup_selection.ec2_selection.name
# }
#
# output "ec2_selection_iam_role" {
#   description = "IAM role ARN for the EC2 backup selection"
#   value       = data.aws_backup_selection.ec2_selection.iam_role_arn
# }
#
# output "ec2_selection_resources" {
#   description = "Resources included in the EC2 backup selection"
#   value       = data.aws_backup_selection.ec2_selection.resources
# }

output "usage_instructions" {
  description = "Instructions for using the backup selection data source"
  value = <<-EOT
    To query the backup selections created by this example:

    1. Get the backup plan ID:
       plan_id = ${module.backup_with_selections.plans["production"].id}

    2. List selection IDs using AWS CLI:
       aws backup list-backup-selections --backup-plan-id ${module.backup_with_selections.plans["production"].id}

    3. Query a specific selection using the data source:
       data "aws_backup_selection" "example" {
         plan_id      = "${module.backup_with_selections.plans["production"].id}"
         selection_id = "<selection-id-from-step-2>"
       }

    4. Access the selection details:
       - name:         data.aws_backup_selection.example.name
       - iam_role_arn: data.aws_backup_selection.example.iam_role_arn
       - resources:    data.aws_backup_selection.example.resources
  EOT
}
