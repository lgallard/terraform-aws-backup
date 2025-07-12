# Compliance-Focused Backup Example
# This example demonstrates backup configurations for regulatory compliance
# including SOC2, HIPAA, PCI DSS, and other industry standards.

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
data "aws_region" "current" {}

# Customer-managed KMS key for backup encryption
resource "aws_kms_key" "backup_key" {
  description             = "KMS key for compliance backup encryption"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Backup Service"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Purpose    = "ComplianceBackup"
    Compliance = var.compliance_framework
  })
}

resource "aws_kms_alias" "backup_key_alias" {
  name          = "alias/compliance-backup-key-${var.environment}"
  target_key_id = aws_kms_key.backup_key.key_id
}

# Compliance backup configuration with vault locking
module "compliance_backup" {
  source = "../.."

  # Vault configuration with compliance settings
  vault_name        = var.vault_name
  vault_kms_key_arn = aws_kms_key.backup_key.arn

  # Vault lock configuration for compliance
  locked              = var.enable_vault_lock
  min_retention_days  = var.min_retention_days
  max_retention_days  = var.max_retention_days
  changeable_for_days = var.changeable_for_days

  # Compliance backup plan
  plan_name = "compliance-backup-plan"

  rules = [
    {
      name              = "compliance-daily-backup"
      schedule          = var.backup_schedule
      start_window      = var.backup_start_window
      completion_window = var.backup_completion_window
      lifecycle = {
        cold_storage_after = var.cold_storage_after_days
        delete_after       = var.retention_days
      }
      recovery_point_tags = merge(var.tags, {
        Compliance     = var.compliance_framework
        RetentionType  = "Regulatory"
        DataClass      = "Sensitive"
        BackupType     = "Compliance"
        CreatedBy      = "TerraformBackup"
        RetentionDays  = tostring(var.retention_days)
      })
    }
  ]

  # Resource selection with compliance tagging
  selection_name = "compliance-resources"
  selection_resources = var.backup_resources
  
  selection_tags = [
    {
      type  = "STRINGEQUALS"
      key   = "Compliance"
      value = var.compliance_framework
    },
    {
      type  = "STRINGEQUALS"
      key   = "DataClassification"
      value = "Sensitive"
    },
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

  # Enable notifications for compliance monitoring
  notifications = var.enable_notifications ? {
    backup_vault_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "BACKUP_JOB_EXPIRED",
      "RESTORE_JOB_STARTED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ]
    sns_topic_arn = var.sns_topic_arn
  } : {}

  tags = merge(var.tags, {
    Purpose    = "ComplianceBackup"
    Compliance = var.compliance_framework
    Locked     = tostring(var.enable_vault_lock)
  })
}

# Compliance audit framework
module "compliance_audit" {
  count  = var.enable_audit_framework ? 1 : 0
  source = "../.."

  # Only create audit framework, not backup resources
  enabled = false

  audit_framework = {
    create      = true
    name        = "${var.compliance_framework}-audit-framework"
    description = "Audit framework for ${var.compliance_framework} compliance requirements"
    controls = concat(
      var.base_audit_controls,
      var.compliance_framework == "SOC2" ? var.soc2_controls : [],
      var.compliance_framework == "HIPAA" ? var.hipaa_controls : [],
      var.compliance_framework == "PCI" ? var.pci_controls : [],
      var.custom_audit_controls
    )
  }

  tags = var.tags
}

# CloudTrail for audit logging (if enabled)
resource "aws_cloudtrail" "compliance_audit" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.vault_name}-audit-trail"
  s3_bucket_name = var.audit_s3_bucket_name
  s3_key_prefix  = "backup-audit-logs/"

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::Backup::RecoveryPoint"
      values = ["*"]
    }

    data_resource {
      type   = "AWS::Backup::BackupVault"
      values = ["*"]
    }
  }

  tags = merge(var.tags, {
    Purpose    = "ComplianceAudit"
    Compliance = var.compliance_framework
  })
}

# Compliance report generation
module "compliance_reports" {
  count  = var.enable_reports ? 1 : 0
  source = "../.."

  # Only create reports, not backup resources
  enabled = false

  reports = [
    {
      name            = "${var.compliance_framework}-compliance-report"
      description     = "Compliance backup report for ${var.compliance_framework}"
      formats         = ["CSV", "JSON"]
      s3_bucket_name  = var.reports_s3_bucket
      s3_key_prefix   = "compliance-reports/${lower(var.compliance_framework)}/"
      report_template = "BACKUP_JOB_REPORT"
      accounts        = [data.aws_caller_identity.current.account_id]
      regions         = var.report_regions
      framework_arns  = var.enable_audit_framework ? [module.compliance_audit[0].audit_framework_arn] : []
    },
    {
      name            = "${var.compliance_framework}-restore-report"
      description     = "Restore testing compliance report for ${var.compliance_framework}"
      formats         = ["CSV"]
      s3_bucket_name  = var.reports_s3_bucket
      s3_key_prefix   = "compliance-reports/${lower(var.compliance_framework)}/restore/"
      report_template = "RESTORE_JOB_REPORT"
      accounts        = [data.aws_caller_identity.current.account_id]
      regions         = var.report_regions
    }
  ]

  tags = var.tags
}

# CloudWatch dashboard for compliance monitoring
resource "aws_cloudwatch_dashboard" "compliance_dashboard" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = "${var.vault_name}-compliance-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", var.vault_name],
            ["AWS/Backup", "NumberOfBackupJobsFailed", "BackupVaultName", var.vault_name],
            ["AWS/Backup", "NumberOfRestoreJobsCompleted", "BackupVaultName", var.vault_name],
            ["AWS/Backup", "NumberOfRestoreJobsFailed", "BackupVaultName", var.vault_name]
          ]
          period = 86400
          stat   = "Sum"
          region = var.region
          title  = "Backup and Restore Job Status"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Backup", "NumberOfRecoveryPointsCreated", "BackupVaultName", var.vault_name]
          ]
          period = 86400
          stat   = "Sum"
          region = var.region
          title  = "Recovery Points Created"
          view   = "timeSeries"
        }
      }
    ]
  })

  tags = var.tags
}

# Compliance alerting
resource "aws_cloudwatch_metric_alarm" "backup_compliance_failure" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.vault_name}-compliance-backup-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Compliance backup job failure detected"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    BackupVaultName = var.vault_name
  }

  tags = merge(var.tags, {
    Severity   = "Critical"
    Compliance = var.compliance_framework
  })
}

resource "aws_cloudwatch_metric_alarm" "backup_compliance_missing" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.vault_name}-compliance-backup-missing"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfBackupJobsCompleted"
  namespace           = "AWS/Backup"
  period              = "86400" # Daily check
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "No backup jobs completed in 24 hours - compliance risk"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    BackupVaultName = var.vault_name
  }

  tags = merge(var.tags, {
    Severity   = "High"
    Compliance = var.compliance_framework
  })
}