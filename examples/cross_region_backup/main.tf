# Cross-Region Backup Example
# This example demonstrates how to create backups with cross-region replication
# for disaster recovery and compliance requirements.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the primary AWS Provider
provider "aws" {
  region = var.primary_region
}

# Configure the secondary AWS Provider for cross-region replication
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create destination vault in secondary region
resource "aws_backup_vault" "secondary_vault" {
  provider = aws.secondary

  name        = "${var.vault_name}-secondary"
  kms_key_arn = var.secondary_vault_kms_key_arn

  tags = merge(var.tags, {
    Purpose = "Cross-region disaster recovery"
    Region  = var.secondary_region
  })
}

# Primary backup configuration with cross-region replication
module "cross_region_backup" {
  source = "../.."

  # Vault configuration
  vault_name        = var.vault_name
  vault_kms_key_arn = var.primary_vault_kms_key_arn

  # Backup plan with cross-region copy actions
  plan_name = "cross-region-backup-plan"

  rules = [
    {
      name              = "cross-region-daily-backup"
      schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM
      start_window      = 60                  # 1 hour window to start
      completion_window = 480                 # 8 hours to complete
      lifecycle = {
        cold_storage_after = 30  # Move to cold storage after 30 days
        delete_after       = 365 # Keep for 1 year
      }
      copy_actions = [
        {
          destination_vault_arn = aws_backup_vault.secondary_vault.arn
          lifecycle = {
            cold_storage_after = 30 # Same lifecycle in secondary region
            delete_after       = 365
          }
        }
      ]
      recovery_point_tags = merge(var.tags, {
        BackupType = "CrossRegion"
        Frequency  = "Daily"
      })
    }
  ]

  # Selection configuration
  selection_name      = "cross-region-resources"
  selection_resources = var.backup_resources

  selection_tags = [
    {
      type  = "STRINGEQUALS"
      key   = "BackupRequired"
      value = "true"
    },
    {
      type  = "STRINGEQUALS"
      key   = "Environment"
      value = var.environment
    }
  ]


  tags = var.tags
}