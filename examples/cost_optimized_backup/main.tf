# Cost-Optimized Backup Example
# This example demonstrates cost optimization strategies for AWS Backup
# including intelligent tiering and resource prioritization.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
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
    # Tier 1: Critical data - Higher frequency, shorter warm storage
    critical_tier = {
      name = "critical-cost-optimized"
      rules = [
        {
          name              = "critical-rapid-backup"
          schedule          = "cron(0 */6 * * ? *)" # Every 6 hours
          start_window      = 60
          completion_window = 180
          lifecycle = {
            cold_storage_after = 1  # Quick transition to save costs
            delete_after       = 30 # Short retention for cost
          }
          recovery_point_tags = {
            CostTier      = "Critical"
            Environment   = var.environment
            CostOptimized = "true"
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

    # Tier 2: Standard data - Balanced approach
    standard_tier = {
      name = "standard-cost-optimized"
      rules = [
        {
          name              = "standard-daily-backup"
          schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM
          start_window      = 120
          completion_window = 240
          lifecycle = {
            cold_storage_after = 30 # Move to cold storage after 30 days
            delete_after       = 90 # 90 days retention
          }
          recovery_point_tags = {
            CostTier      = "Standard"
            Environment   = var.environment
            CostOptimized = "true"
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

    # Tier 3: Development - Minimal cost
    development_tier = {
      name = "development-minimal-cost"
      rules = [
        {
          name              = "development-weekly-backup"
          schedule          = "cron(0 1 ? * SUN *)" # Weekly on Sunday
          start_window      = 240
          completion_window = 480
          lifecycle = {
            cold_storage_after = 0 # No cold storage for dev
            delete_after       = 7 # Short retention
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