#!/bin/bash

# Migration script for moving from single plan to multiple plans
# Run this after updating your configuration to use the plans variable

echo "Starting migration from single plan to multiple plans..."

# Check if resources exist before migration
echo "Checking current backup resources..."
terraform state list | grep "aws_backup_plan\|aws_backup_selection"

echo ""
echo "Moving backup plan..."
terraform state mv \
  'module.aws_backup_example.aws_backup_plan.ab_plan[0]' \
  'module.aws_backup_example.aws_backup_plan.ab_plans["default"]'

echo ""
echo "Moving backup selections..."
terraform state mv \
  'module.aws_backup_example.aws_backup_selection.ab_selections["production-dbs"]' \
  'module.aws_backup_example.aws_backup_selection.plan_selections["default-production-dbs"]'

terraform state mv \
  'module.aws_backup_example.aws_backup_selection.ab_selections["development-dbs"]' \
  'module.aws_backup_example.aws_backup_selection.plan_selections["default-development-dbs"]'

echo ""
echo "Migration complete! Verifying with terraform plan..."
terraform plan

echo ""
echo "If the plan shows 'No changes', migration was successful!"
echo "If there are changes, please review the state moves and configuration."