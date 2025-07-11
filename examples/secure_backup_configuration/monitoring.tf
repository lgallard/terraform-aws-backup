# CloudWatch monitoring and alerting for backup security

# CloudWatch Log Group for backup events
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/backup/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.backup_key.arn
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-logs"
  })
}

# CloudWatch Alarms for backup security monitoring

# Alarm for failed backup jobs
resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-job-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors failed backup jobs"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]
  
  dimensions = {
    BackupVaultName = module.backup.backup_vault_id
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-job-failed"
  })
}

# Alarm for successful backup jobs (should have at least daily backups)
resource "aws_cloudwatch_metric_alarm" "backup_job_success" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-job-success"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsCompleted"
  namespace           = "AWS/Backup"
  period              = "86400"  # 24 hours
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors that at least one backup job completed in the last 24 hours"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]
  
  dimensions = {
    BackupVaultName = module.backup.backup_vault_id
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-job-success"
  })
}

# Alarm for KMS key usage (security monitoring)
resource "aws_cloudwatch_metric_alarm" "kms_key_usage" {
  alarm_name          = "${var.project_name}-${var.environment}-kms-key-unusual-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfRequestsSucceeded"
  namespace           = "AWS/KMS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"  # Adjust based on normal usage
  alarm_description   = "This metric monitors unusual KMS key usage patterns"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]
  
  dimensions = {
    KeyId = aws_kms_key.backup_key.key_id
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kms-key-usage"
  })
}

# Alarm for backup vault access (security monitoring)
resource "aws_cloudwatch_metric_alarm" "backup_vault_access" {
  alarm_name          = "${var.project_name}-${var.environment}-backup-vault-unusual-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupVaultDeletions"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup vault deletion attempts"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]
  
  dimensions = {
    BackupVaultName = module.backup.backup_vault_id
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-vault-access"
  })
}

# CloudWatch Dashboard for backup monitoring
resource "aws_cloudwatch_dashboard" "backup_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-backup-security-dashboard"
  
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
            ["AWS/Backup", "NumberOfBackupJobsCompleted", "BackupVaultName", module.backup.backup_vault_id],
            [".", "NumberOfBackupJobsFailed", ".", "."],
            [".", "NumberOfBackupJobsRunning", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Backup Job Status"
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
            ["AWS/KMS", "NumberOfRequestsSucceeded", "KeyId", aws_kms_key.backup_key.key_id],
            [".", "NumberOfRequestsFailed", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "KMS Key Usage"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        
        properties = {
          query = "SOURCE '${aws_cloudwatch_log_group.backup_logs.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 100"
          region = data.aws_region.current.name
          title  = "Recent Backup Errors"
        }
      }
    ]
  })
}

# Custom CloudWatch metric for backup compliance
resource "aws_cloudwatch_log_metric_filter" "backup_compliance" {
  name           = "${var.project_name}-${var.environment}-backup-compliance"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name
  pattern        = "[timestamp, request_id, event_type=\"BACKUP_JOB_COMPLETED\", ...]"
  
  metric_transformation {
    name      = "BackupComplianceEvents"
    namespace = "Custom/Backup"
    value     = "1"
  }
}

# Security-focused CloudWatch Insights queries
resource "aws_cloudwatch_query_definition" "backup_security_analysis" {
  name = "${var.project_name}-${var.environment}-backup-security-analysis"
  
  log_group_names = [aws_cloudwatch_log_group.backup_logs.name]
  
  query_string = <<EOF
fields @timestamp, @message
| filter @message like /BACKUP_JOB_FAILED/ or @message like /RESTORE_JOB_FAILED/
| stats count() by bin(5m)
| sort @timestamp desc
EOF
}

resource "aws_cloudwatch_query_definition" "backup_encryption_analysis" {
  name = "${var.project_name}-${var.environment}-backup-encryption-analysis"
  
  log_group_names = [aws_cloudwatch_log_group.backup_logs.name]
  
  query_string = <<EOF
fields @timestamp, @message
| filter @message like /kms/ or @message like /encryption/
| stats count() by bin(1h)
| sort @timestamp desc
EOF
}