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

# Helper output: Ready-to-run AWS CLI command to list selection IDs
output "cli_list_selections" {
  description = "AWS CLI command to list all backup selection IDs (copy and run)"
  value       = "aws backup list-backup-selections --backup-plan-id ${module.backup_with_selections.plans["production"].id}"
}

# Helper output: AWS CLI command with table output
output "cli_list_selections_table" {
  description = "AWS CLI command to list selections in table format (copy and run)"
  value       = "aws backup list-backup-selections --backup-plan-id ${module.backup_with_selections.plans["production"].id} --query 'BackupSelectionsList[*].[SelectionId,SelectionName,IamRoleArn]' --output table"
}

# Helper output: JQ one-liner to extract selection IDs
output "cli_extract_ids_jq" {
  description = "AWS CLI with jq to extract selection IDs and names (copy and run)"
  value       = "aws backup list-backup-selections --backup-plan-id ${module.backup_with_selections.plans["production"].id} | jq -r '.BackupSelectionsList[] | \"\\(.SelectionName): \\(.SelectionId)\"'"
}

# Helper output: Complete script to save selection IDs as Terraform variables
output "helper_script" {
  description = "Helper script to generate terraform.tfvars with selection IDs"
  value       = <<-EOT
    #!/bin/bash
    # Helper script to extract selection IDs and create terraform.tfvars

    PLAN_ID="${module.backup_with_selections.plans["production"].id}"

    echo "Fetching backup selections for plan: $PLAN_ID"
    echo ""

    aws backup list-backup-selections --backup-plan-id "$PLAN_ID" \
      --query 'BackupSelectionsList[*].[SelectionName,SelectionId]' \
      --output text | while read -r name id; do
      echo "# $name"
      echo "# To use this selection, uncomment the data source in main.tf and set:"
      echo "# selection_id = \"$id\""
      echo ""
    done
  EOT
}

output "usage_instructions" {
  description = "Quick start guide for using the backup selection data source"
  value       = <<-EOT
    📋 QUICK START GUIDE

    The backup plan has been created successfully!
    Plan ID: ${module.backup_with_selections.plans["production"].id}

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    To use the aws_backup_selection data source, follow these steps:

    STEP 1: Get Selection IDs (choose one method)

    Option A - Table Format (recommended for viewing):
      ${self.cli_list_selections_table}

    Option B - JSON with jq (best for scripting):
      ${self.cli_extract_ids_jq}

    Option C - Raw JSON:
      ${self.cli_list_selections}

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    STEP 2: Use the Selection ID in your Terraform configuration

    Uncomment the data source in main.tf and replace the selection_id:

    data "aws_backup_selection" "ec2_selection" {
      plan_id      = "${module.backup_with_selections.plans["production"].id}"
      selection_id = "YOUR-SELECTION-ID-FROM-STEP-1"
    }

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    STEP 3: Access the selection data

    Output examples:
      - Name:       data.aws_backup_selection.ec2_selection.name
      - IAM Role:   data.aws_backup_selection.ec2_selection.iam_role_arn
      - Resources:  data.aws_backup_selection.ec2_selection.resources

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    💡 TIP: Save the helper_script output to a file and run it:
       terraform output -raw helper_script > get_selections.sh
       chmod +x get_selections.sh
       ./get_selections.sh
  EOT
}
