# Secure AWS Backup Configuration Example
# This example demonstrates security best practices for AWS Backup

# Local values for consistent naming and tagging
locals {
  common_tags = {
    Environment   = var.environment
    Project       = var.project_name
    Owner         = var.owner
    CreatedBy     = "terraform"
    SecurityLevel = "high"
    Compliance    = "required"
  }
  
  vault_name = "${var.project_name}-${var.environment}-secure-vault"
  plan_name  = "${var.project_name}-${var.environment}-secure-plan"
}

# Main backup configuration with security best practices
module "backup" {
  source = "../../"

  # Vault configuration with security controls
  vault_name        = local.vault_name
  vault_kms_key_arn = aws_kms_key.backup_key.arn
  
  # Enable vault lock for compliance
  locked              = var.enable_vault_lock
  changeable_for_days = var.vault_lock_changeable_days
  
  # Security-focused retention policies
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days
  
  # Backup plan with security controls
  plan_name = local.plan_name
  
  rules = [
    {
      name                     = "daily-secure-backup"
      schedule                 = "cron(0 5 ? * * *)"  # 5 AM UTC daily
      start_window             = 480                   # 8 hours
      completion_window        = 10080                 # 7 days
      enable_continuous_backup = var.enable_continuous_backup
      
      lifecycle = {
        cold_storage_after = 30   # Move to cold storage after 30 days
        delete_after       = var.backup_retention_days
      }
      
      # Security-focused tagging
      recovery_point_tags = merge(local.common_tags, {
        BackupType = "daily"
        Encrypted  = "true"
      })
      
      # Cross-region backup with security controls
      copy_actions = var.enable_cross_region_backup ? [
        {
          destination_vault_arn = aws_backup_vault.cross_region_vault[0].arn
          lifecycle = {
            cold_storage_after = 30
            delete_after       = var.backup_retention_days
          }
        }
      ] : []
    },
    {
      name                     = "weekly-secure-backup"
      schedule                 = "cron(0 6 ? * SUN *)"  # 6 AM UTC on Sundays
      start_window             = 480
      completion_window        = 10080
      enable_continuous_backup = false
      
      lifecycle = {
        cold_storage_after = 90   # Move to cold storage after 90 days
        delete_after       = var.weekly_backup_retention_days
      }
      
      recovery_point_tags = merge(local.common_tags, {
        BackupType = "weekly"
        Encrypted  = "true"
      })
    }
  ]
  
  # Secure backup selections
  selections = {
    "production-databases" = {
      resources = var.database_resources
      
      # Security-focused resource selection
      conditions = {
        "string_equals" = {
          "aws:ResourceTag/Environment"   = var.environment
          "aws:ResourceTag/SecurityLevel" = "high"
          "aws:ResourceTag/BackupRequired" = "true"
        }
      }
      
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = var.environment
        },
        {
          type  = "STRINGEQUALS"
          key   = "SecurityLevel"
          value = "high"
        }
      ]
    },
    
    "production-volumes" = {
      resources = var.volume_resources
      
      conditions = {
        "string_equals" = {
          "aws:ResourceTag/Environment"   = var.environment
          "aws:ResourceTag/SecurityLevel" = "high"
          "aws:ResourceTag/BackupRequired" = "true"
        }
      }
    }
  }
  
  # Security notifications
  notifications = {
    backup_vault_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_STARTED", 
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ]
    sns_topic_arn = aws_sns_topic.backup_notifications.arn
  }
  
  # Security-focused tagging
  tags = local.common_tags
}

# Cross-region backup vault for disaster recovery
resource "aws_backup_vault" "cross_region_vault" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  name        = "${local.vault_name}-cross-region"
  kms_key_arn = aws_kms_key.cross_region_backup_key[0].arn
  
  # Enable vault lock for compliance
  dynamic "lock_configuration" {
    for_each = var.enable_vault_lock ? [1] : []
    
    content {
      changeable_for_days = var.vault_lock_changeable_days
      min_retention_days  = var.min_retention_days
      max_retention_days  = var.max_retention_days
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.vault_name}-cross-region"
    Type = "cross-region"
  })
  
  provider = aws.cross_region
}

# SNS topic for security notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.project_name}-${var.environment}-backup-notifications"
  
  # Enable encryption for SNS
  kms_master_key_id = aws_kms_key.sns_key.arn
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-notifications"
  })
}

# SNS topic policy for backup service
resource "aws_sns_topic_policy" "backup_notifications" {
  arn = aws_sns_topic.backup_notifications.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBackupServiceToPublish"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.backup_notifications.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email subscription for notifications
resource "aws_sns_topic_subscription" "backup_notifications_email" {
  count = var.notification_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}