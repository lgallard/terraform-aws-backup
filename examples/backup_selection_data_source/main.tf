# Backup Selection Data Source Example
# This example demonstrates how to query existing backup selections
# using the aws_backup_selection data source.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

#
# Step 1: Create a backup configuration with selections
#
module "backup_with_selections" {
  source = "../.."

  vault_name = var.vault_name

  # Create a backup plan with multiple selections
  plans = {
    production = {
      name = "production-backup-plan"
      rules = [
        {
          name              = "daily-backup"
          schedule          = "cron(0 2 * * ? *)"
          start_window      = 60
          completion_window = 180
          lifecycle = {
            delete_after = 30
          }
        }
      ]
      selections = {
        # Selection 1: EC2 instances
        ec2_instances = {
          resources = [
            "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Backup"
              value = "true"
            }
          ]
        }

        # Selection 2: RDS databases
        rds_databases = {
          resources = [
            "arn:aws:rds:${var.region}:${data.aws_caller_identity.current.account_id}:db:*"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = "production"
            }
          ]
        }

        # Selection 3: DynamoDB tables
        dynamodb_tables = {
          resources = [
            "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/*"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "CriticalData"
              value = "true"
            }
          ]
        }
      }
    }
  }

  tags = var.tags
}

#
# Step 2: Query the backup selections using data sources
#
# Note: The aws_backup_selection data source requires selection_id,
# which is the unique identifier AWS assigns to each selection.
# These IDs are available in the AWS Console or via AWS CLI:
# aws backup list-backup-selections --backup-plan-id <plan-id>
#

# Example: Query a specific backup selection
# Uncomment and provide the actual selection_id to use this:
#
# data "aws_backup_selection" "ec2_selection" {
#   plan_id      = module.backup_with_selections.plans["production"].id
#   selection_id = "your-selection-id-from-aws"
# }
#
# Access the selection details:
# - data.aws_backup_selection.ec2_selection.name
# - data.aws_backup_selection.ec2_selection.iam_role_arn
# - data.aws_backup_selection.ec2_selection.resources

#
# Step 3: Use the data source to reference external backup selections
#
# If you need to query backup selections created outside this module:
#
# data "aws_backup_plan" "existing_plan" {
#   plan_id = var.existing_plan_id
# }
#
# data "aws_backup_selection" "existing_selection" {
#   plan_id      = data.aws_backup_plan.existing_plan.id
#   selection_id = var.existing_selection_id
# }
