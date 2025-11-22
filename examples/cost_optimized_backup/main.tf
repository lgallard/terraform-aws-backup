# Cost-Optimized Backup Example
# This example demonstrates cost optimization strategies for AWS Backup
# including intelligent tiering and resource prioritization.

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

# Cost-optimized backup configuration with multiple tiers
module "cost_optimized_backup" {
  source = "../.."

  vault_name        = var.vault_name
  vault_kms_key_arn = var.vault_kms_key_arn

  # Multi-tier backup strategy for cost optimization
  plans = {
    # Tier 1: Critical data - Higher frequency, archive-enabled for maximum cost savings
    critical_tier = {
      name = "critical-cost-optimized"
      rules = [
        {
          name                         = "critical-rapid-backup"
          schedule                     = "cron(0 */6 * * ? *)" # Every 6 hours
          schedule_expression_timezone = var.backup_timezone
          start_window                 = 60
          completion_window            = 180
          lifecycle = {
            cold_storage_after                        = 30   # Move to cold storage after 30 days (AWS minimum)
            delete_after                              = 90   # Retention period
            opt_in_to_archive_for_supported_resources = true # Enable archive tier for 90% cost savings
          }
          recovery_point_tags = {
            CostTier       = "Critical"
            Environment    = var.environment
            CostOptimized  = "true"
            ArchiveEnabled = "true"
          }
        }
      ]
      selections = {
        critical_resources = {
          resources = var.critical_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "CostTier"
              value = "Critical"
            }
          ]
        }
      }
    }

    # Tier 2: Standard data - Balanced approach with archive tier
    standard_tier = {
      name = "standard-cost-optimized"
      rules = [
        {
          name                         = "standard-daily-backup"
          schedule                     = "cron(0 2 * * ? *)" # Daily at 2 AM
          schedule_expression_timezone = var.backup_timezone
          start_window                 = 120
          completion_window            = 240
          lifecycle = {
            cold_storage_after                        = 30   # Move to cold storage after 30 days
            delete_after                              = 90   # 90 days retention
            opt_in_to_archive_for_supported_resources = true # Enable archive tier for cost savings
          }
          recovery_point_tags = {
            CostTier       = "Standard"
            Environment    = var.environment
            CostOptimized  = "true"
            ArchiveEnabled = "true"
          }
        }
      ]
      selections = {
        standard_resources = {
          resources = var.standard_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "CostTier"
              value = "Standard"
            }
          ]
        }
      }
    }

    # Tier 3: Development - Minimal cost (no archive needed for short retention)
    development_tier = {
      name = "development-minimal-cost"
      rules = [
        {
          name                         = "development-weekly-backup"
          schedule                     = "cron(0 1 ? * SUN *)" # Weekly on Sunday
          schedule_expression_timezone = var.backup_timezone
          start_window                 = 240
          completion_window            = 480
          lifecycle = {
            delete_after = 7 # Short retention - no archive tier needed
          }
          recovery_point_tags = {
            CostTier      = "Development"
            Environment   = "development"
            CostOptimized = "true"
          }
        }
      ]
      selections = {
        development_resources = {
          resources = var.development_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = "development"
            }
          ]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Purpose      = "CostOptimizedBackup"
    CostStrategy = "MultiTier"
  })
}
