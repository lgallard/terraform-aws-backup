# CloudWatch monitoring and alerting for backup security

# Local values for monitoring optimization
locals {
  current_region = local.current_region
}

# CloudWatch Log Group for CloudTrail backup events (optional, used if CloudTrail sends logs here)
# NOTE: This log group is created for potential CloudTrail integration
# If not using CloudTrail for backup audit logging, this can be omitted
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}-backup"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.backup_key.arn

  tags = merge(local.common_tags, {
    Name    = "backup-cloudtrail-logs"
    Purpose = "audit-logging"
    Service = "cloudtrail"
  })
}

# CloudWatch Event Rule for backup job failures
resource "aws_cloudwatch_event_rule" "backup_failure" {
  name        = "${var.project_name}-${var.environment}-backup-failure"
  description = "Capture backup job failures for security monitoring"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["FAILED", "EXPIRED"]
    }
  })

  tags = local.common_tags
}

# CloudWatch Metric Alarm for backup job failures
resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-job-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup job failures for security compliance"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    BackupVaultName = module.backup.vault_id
  }

  tags = merge(local.common_tags, {
    AlarmType   = "security"
    Criticality = "high"
  })
}

# CloudWatch Metric Alarm for successful backup jobs (should be > 0)
resource "aws_cloudwatch_metric_alarm" "backup_job_success" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-job-success"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfBackupJobsCompleted"
  namespace           = "AWS/Backup"
  period              = "86400"  # Daily check
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors successful backup job completion for security compliance"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  ok_actions          = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "breaching"

  dimensions = {
    BackupVaultName = module.backup.vault_id
  }

  tags = merge(local.common_tags, {
    AlarmType   = "compliance"
    Criticality = "medium"
  })
}

# CloudWatch Metric Filter for backup vault events (using CloudTrail patterns)
resource "aws_logs_metric_filter" "vault_access" {
  name           = "${var.project_name}-${var.environment}-vault-access"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name
  # Updated pattern to match actual AWS Backup CloudTrail events
  pattern        = "{ $.eventSource = \"backup.amazonaws.com\" && ($.eventName = \"GetBackupVault*\" || $.eventName = \"DeleteBackupVault*\" || $.eventName = \"PutBackupVault*\") }"

  metric_transformation {
    name      = "VaultAccess"
    namespace = "BackupSecurity/${var.project_name}"
    value     = "1"
    
    # Add security context to metrics
    default_value = "0"
  }
}

# CloudWatch Metric Alarm for unusual vault access patterns
resource "aws_cloudwatch_metric_alarm" "backup_vault_access" {
  alarm_name          = "${var.project_name}-${var.environment}-unusual-vault-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VaultAccess"
  namespace           = "BackupSecurity/${var.project_name}"
  period              = "900"  # 15 minutes
  statistic           = "Sum"
  threshold           = var.vault_access_alarm_threshold
  alarm_description   = "This metric monitors unusual backup vault access patterns for security"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
  treat_missing_data  = "notBreaching"

  dimensions = {
    BackupVaultName = module.backup.vault_id
  }

  tags = merge(local.common_tags, {
    AlarmType   = "security"
    Criticality = "medium"
  })
}

# CloudWatch Dashboard for backup security monitoring
resource "aws_cloudwatch_dashboard" "backup_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-backup-security"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", module.backup.vault_id],
            ["AWS/Backup", "NumberOfBackupJobsFailed", "BackupVaultName", module.backup.vault_id],
            ["AWS/Backup", "NumberOfBackupJobsPending", "BackupVaultName", module.backup.vault_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.current_region
          title   = "Backup Job Status"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["BackupSecurity/${var.project_name}", "VaultAccess", "BackupVaultName", module.backup.vault_id]
          ]
          view   = "timeSeries"
          region = local.current_region
          title  = "Vault Access Patterns"
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "log"
        width  = 24
        height = 6
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.backup_logs.name}' | fields @timestamp, eventSource, eventName, sourceIPAddress, userIdentity.type\n| filter eventSource = \"backup.amazonaws.com\"\n| sort @timestamp desc\n| limit 100"
          region  = local.current_region
          title   = "Recent Vault Access Events"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Purpose = "security-monitoring"
  })
}

# Security-focused SNS topic for backup alerts (conditional)
resource "aws_sns_topic" "backup_security_alerts" {
  count = var.create_sns_topic ? 1 : 0

  name         = "${var.project_name}-${var.environment}-backup-security-alerts"
  display_name = "Backup Security Alerts"
  
  # Enable encryption for sensitive backup notifications
  kms_master_key_id = aws_kms_key.backup_key.key_id

  tags = merge(local.common_tags, {
    Purpose = "security-alerts"
  })
}

# SNS topic policy for secure access
resource "aws_sns_topic_policy" "backup_security_alerts" {
  count = var.create_sns_topic ? 1 : 0

  arn = aws_sns_topic.backup_security_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.backup_security_alerts[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
