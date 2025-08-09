# Secure AWS Backup Configuration Example
# This example demonstrates enterprise-grade backup security practices

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.cross_region]
    }
  }
}

# Data sources for account and region information
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_region" "cross_region" {
  provider = aws.cross_region
}

# Local values for consistent resource naming and configuration
locals {
  vault_name = "${var.project_name}-${var.environment}-backup-vault"
  
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
    Purpose       = "backup"
    SecurityLevel = "high"
    Compliance    = "required"
    CreatedBy     = "secure-backup-example"
  }

  # Security-focused backup rules with encryption and compliance
  backup_rules = {
    critical_daily = {
      name              = "critical-daily-encrypted"
      schedule          = "cron(0 3 ? * * *)"
      start_window      = 60
      completion_window = 300
      lifecycle = {
        cold_storage_after = 30
        delete_after       = var.retention_days
      }
      copy_actions = var.enable_cross_region_backup ? [{
        destination_backup_vault_arn = "arn:aws:backup:${var.cross_region_name}:${data.aws_caller_identity.current.account_id}:backup-vault:${local.vault_name}-cross-region"
        lifecycle = {
          cold_storage_after = 30
          delete_after       = var.retention_days
        }
      }] : []
      recovery_point_tags = {
        BackupType   = "daily"
        Criticality  = "high"
        Environment  = var.environment
        Encrypted    = "true"
        Compliance   = "required"
      }
    }
    weekly_long_term = {
      name              = "weekly-long-term-encrypted"
      schedule          = "cron(0 4 ? * SUN *)"
      start_window      = 60
      completion_window = 480
      lifecycle = {
        cold_storage_after = 7
        delete_after       = var.long_term_retention_days
      }
      copy_actions = var.enable_cross_region_backup ? [{
        destination_backup_vault_arn = "arn:aws:backup:${var.cross_region_name}:${data.aws_caller_identity.current.account_id}:backup-vault:${local.vault_name}-cross-region"
        lifecycle = {
          cold_storage_after = 7
          delete_after       = var.long_term_retention_days
        }
      }] : []
      recovery_point_tags = {
        BackupType   = "weekly"
        Criticality  = "high"
        Environment  = var.environment
        Encrypted    = "true"
        Compliance   = "required"
        LongTerm     = "true"
      }
    }
  }

  # Security-focused backup selections with specific resource targeting
  backup_selections = {
    production_databases = {
      name = "production-databases-secure"
      # Use tag-based selection for better security instead of wildcard ARNs
      resources = ["*"]
      conditions = [
        {
          string_equals = {
            key   = "aws:tag/Environment"
            value = var.environment
          }
        },
        {
          string_equals = {
            key   = "aws:tag/BackupRequired"
            value = "true"
          }
        },
        {
          string_equals = {
            key   = "aws:tag/ResourceType"
            value = "Database"
          }
        }
      ]
    }
    critical_file_systems = {
      name = "critical-file-systems-secure"
      # Use tag-based selection for better security
      resources = ["*"]
      conditions = [
        {
          string_equals = {
            key   = "aws:tag/Environment"
            value = var.environment
          }
        },
        {
          string_equals = {
            key   = "aws:tag/BackupTier"
            value = "critical"
          }
        },
        {
          string_equals = {
            key   = "aws:tag/ResourceType"
            value = "FileSystem"
          }
        }
      ]
    }
  }
}

# Secure backup module configuration
module "backup" {
  source = "../.."

  enabled = true

  # Vault configuration with KMS encryption
  vault_name    = local.vault_name
  vault_kms_key = aws_kms_key.backup_key.arn

  # Enable vault lock for compliance (if specified)
  locked                 = var.enable_vault_lock
  min_retention_days     = var.min_retention_days
  max_retention_days     = var.max_retention_days

  # Security-focused backup plans
  plans = {
    secure_backup_plan = {
      name  = "${var.project_name}-${var.environment}-secure-plan"
      rules = values(local.backup_rules)
    }
  }

  # Secure backup selections
  backup_selections = values(local.backup_selections)

  # Security and compliance tags
  tags = local.common_tags
}

# Cross-region backup vault for disaster recovery (conditional)
resource "aws_backup_vault" "cross_region_vault" {
  count = var.enable_cross_region_backup ? 1 : 0

  provider = aws.cross_region

  name        = "${local.vault_name}-cross-region"
  kms_key_arn = aws_kms_key.cross_region_backup_key[0].arn

  # Enable vault lock for compliance - use backup vault lock resource instead
  # NOTE: vault lock should be configured using aws_backup_vault_lock_configuration resource

  tags = merge(local.common_tags, {
    Name = "${local.vault_name}-cross-region"
    Type = "cross-region"
    Region = var.cross_region_name
  })
}

# Vault lock configuration for compliance (conditional)
resource "aws_backup_vault_lock_configuration" "this" {
  count = var.enable_vault_lock ? 1 : 0

  backup_vault_name   = module.backup.vault_id
  changeable_for_days = var.vault_lock_changeable_days
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
}

# Cross-region vault lock (conditional)
resource "aws_backup_vault_lock_configuration" "cross_region" {
  count = var.enable_cross_region_backup && var.enable_vault_lock ? 1 : 0

  provider = aws.cross_region

  backup_vault_name   = aws_backup_vault.cross_region_vault[0].name
  changeable_for_days = var.vault_lock_changeable_days
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
}
