# AWS Backup Best Practices

This guide outlines best practices for using AWS Backup with the terraform-aws-backup module to ensure secure, efficient, and cost-effective backup operations.

## Table of Contents

- [Security Best Practices](#security-best-practices)
- [Performance Optimization](#performance-optimization)
- [Cost Management](#cost-management)
- [Monitoring and Alerting](#monitoring-and-alerting)
- [Compliance and Governance](#compliance-and-governance)
- [Disaster Recovery](#disaster-recovery)
- [Operational Excellence](#operational-excellence)

## Security Best Practices

### 1. Encryption at Rest and in Transit

**Use Customer-Managed KMS Keys**
```hcl
# Create dedicated KMS key for backups
resource "aws_kms_key" "backup" {
  description             = "Backup vault encryption key"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Use the key in backup vault
module "backup" {
  source = "lgallard/backup/aws"

  vault_name        = "secure-backup-vault"
  vault_kms_key_arn = aws_kms_key.backup.arn
}
```

### 2. Vault Lock Configuration

**Enable Vault Lock for Compliance**
```hcl
module "backup" {
  source = "lgallard/backup/aws"

  vault_name           = "compliance-vault"
  locked               = true
  changeable_for_days  = 3      # Governance mode
  min_retention_days   = 30     # Minimum retention
  max_retention_days   = 2555   # Maximum retention (7 years)
}
```

### 3. IAM Security

**Use Least Privilege Access**
```hcl
# Create minimal IAM role for backup operations
resource "aws_iam_role" "backup_role" {
  name = "backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Attach minimal required policies
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}
```

**Avoid Overly Permissive Naming**
```hcl
# Good: Specific, descriptive names
vault_name = "prod-backup-vault-${random_id.suffix.hex}"

# Avoid: Generic or test-related names
# vault_name = "test-vault"
# vault_name = "temp-backup"
```

### 4. Cross-Account Access

**Secure Cross-Account Backup**
```hcl
# Source account configuration
module "backup_source" {
  source = "lgallard/backup/aws"

  vault_name = "source-backup-vault"

  rules = [
    {
      name = "cross_account_backup"
      schedule = "cron(0 2 * * ? *)"
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-west-2:DEST-ACCOUNT:backup-vault:dest-vault"
          lifecycle = {
            delete_after = 30
          }
        }
      ]
    }
  ]
}

# Destination account vault policy
resource "aws_backup_vault_policy" "cross_account" {
  backup_vault_name = "dest-vault"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::SOURCE-ACCOUNT:root"
        }
        Action = [
          "backup:CopyIntoBackupVault"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "backup:CopySourceArn" = "arn:aws:backup:us-east-1:SOURCE-ACCOUNT:backup-vault:source-vault"
          }
        }
      }
    ]
  })
}
```

## Performance Optimization

### 1. Backup Window Optimization

**Size-Based Window Configuration**
```hcl
# Small resources (< 1GB)
rules = [
  {
    name              = "small_resources"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 60    # 1 hour
    completion_window = 120   # 2 hours
  }
]

# Medium resources (1-100GB)
rules = [
  {
    name              = "medium_resources"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 120   # 2 hours
    completion_window = 480   # 8 hours
  }
]

# Large resources (> 100GB)
rules = [
  {
    name              = "large_resources"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 240   # 4 hours
    completion_window = 1440  # 24 hours
  }
]
```

### 2. Schedule Optimization

**Staggered Backup Schedules**
```hcl
# Stagger backups to avoid resource contention
plans = {
  "critical-systems" = {
    rules = [
      {
        name     = "critical_backup"
        schedule = "cron(0 1 * * ? *)"  # 1 AM
        lifecycle = {
          delete_after = 90
        }
      }
    ]
  }
  "standard-systems" = {
    rules = [
      {
        name     = "standard_backup"
        schedule = "cron(0 3 * * ? *)"  # 3 AM
        lifecycle = {
          delete_after = 30
        }
      }
    ]
  }
}
```

### 3. Resource-Specific Optimization

**EFS Performance Optimization**
```hcl
# For large EFS file systems
rules = [
  {
    name              = "efs_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 240     # 4 hours
    completion_window = 2880    # 48 hours for very large EFS
    lifecycle = {
      cold_storage_after = 30
      delete_after       = 365
    }
  }
]
```

**RDS Optimization**
```hcl
# Coordinate with RDS automated backups
rules = [
  {
    name     = "rds_backup"
    schedule = "cron(0 4 * * ? *)"  # After automated backups typically complete
    lifecycle = {
      delete_after = 7  # Short retention for frequent backups
    }
  }
]
```

## Cost Management

### 1. Lifecycle Management

**Tiered Storage Strategy**
```hcl
# Cost-optimized lifecycle
rules = [
  {
    name = "cost_optimized_backup"
    schedule = "cron(0 2 * * ? *)"
    lifecycle = {
      cold_storage_after = 30   # Move to cold storage after 30 days
      delete_after       = 365  # Retain for 1 year
    }
  }
]

# Compliance-focused lifecycle
rules = [
  {
    name = "compliance_backup"
    schedule = "cron(0 2 * * ? *)"
    lifecycle = {
      cold_storage_after = 90   # Move to cold storage after 90 days
      delete_after       = 2555 # Retain for 7 years
    }
  }
]
```

### 2. Backup Frequency Optimization

**Frequency by Criticality**
```hcl
# Critical systems: Daily backups
critical_rules = [
  {
    name     = "critical_daily"
    schedule = "cron(0 2 * * ? *)"
    lifecycle = {
      delete_after = 30
    }
  }
]

# Standard systems: Weekly backups
standard_rules = [
  {
    name     = "standard_weekly"
    schedule = "cron(0 2 ? * SUN *)"  # Weekly on Sunday
    lifecycle = {
      delete_after = 90
    }
  }
]

# Archive systems: Monthly backups
archive_rules = [
  {
    name     = "archive_monthly"
    schedule = "cron(0 2 1 * ? *)"   # Monthly on 1st
    lifecycle = {
      cold_storage_after = 30
      delete_after       = 365
    }
  }
]
```

### 3. Resource Targeting

**Selective Backup Strategies**
```hcl
# Production resources only
selections = {
  "production-resources" = {
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:rds:*:*:db:prod-*",
      "arn:aws:dynamodb:*:*:table/prod-*"
    ]
    selection_tags = [
      {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "production"
      }
    ]
  }
}

# Exclude non-critical resources
selections = {
  "filtered-resources" = {
    not_resources = [
      "arn:aws:ec2:*:*:volume/vol-temp-*",
      "arn:aws:rds:*:*:db:test-*"
    ]
  }
}
```

## Monitoring and Alerting

### 1. CloudWatch Alarms

**Backup Job Monitoring**
```hcl
resource "aws_cloudwatch_metric_alarm" "backup_job_failed" {
  alarm_name          = "backup-job-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Backup job failed"
  alarm_actions       = [aws_sns_topic.backup_alerts.arn]

  dimensions = {
    BackupVaultName = module.backup.backup_vault_name
  }
}

resource "aws_cloudwatch_metric_alarm" "backup_job_expired" {
  alarm_name          = "backup-job-expired"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsExpired"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Backup job expired"
  alarm_actions       = [aws_sns_topic.backup_alerts.arn]
}
```

### 2. SNS Notifications

**Comprehensive Notification Setup**
```hcl
module "backup" {
  source = "lgallard/backup/aws"

  notifications = {
    backup_vault_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "BACKUP_JOB_EXPIRED",
      "RESTORE_JOB_STARTED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED",
      "COPY_JOB_STARTED",
      "COPY_JOB_SUCCESSFUL",
      "COPY_JOB_FAILED",
      "RECOVERY_POINT_MODIFIED"
    ]
    sns_topic_arn = aws_sns_topic.backup_notifications.arn
  }
}
```

### 3. Custom Metrics

**Track Backup Success Rate**
```hcl
resource "aws_cloudwatch_log_metric_filter" "backup_success_rate" {
  name           = "backup-success-rate"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name

  pattern = "[timestamp, request_id, event_type=\"BACKUP_JOB_COMPLETED\"]"

  metric_transformation {
    name      = "BackupSuccessRate"
    namespace = "Custom/Backup"
    value     = "1"
  }
}
```

## Compliance and Governance

### 1. Tagging Strategy

**Comprehensive Tagging**
```hcl
module "backup" {
  source = "lgallard/backup/aws"

  tags = {
    Environment   = "production"
    Project       = "backup-infrastructure"
    Owner         = "platform-team"
    CostCenter    = "infrastructure"
    Compliance    = "required"
    BackupClass   = "critical"
    DataClass     = "confidential"
    RetentionDays = "365"
  }

  # Tag recovery points
  rules = [
    {
      name = "tagged_backup"
      schedule = "cron(0 2 * * ? *)"
      recovery_point_tags = {
        BackupDate    = "auto-generated"
        DataOwner     = "platform-team"
        RestoreReady  = "true"
        ComplianceId  = "COMP-001"
      }
    }
  ]
}
```

### 2. Backup Reporting

**Automated Compliance Reports**
```hcl
module "backup" {
  source = "lgallard/backup/aws"

  reports = [
    {
      name            = "compliance-backup-report"
      description     = "Monthly backup compliance report"
      formats         = ["CSV", "JSON"]
      s3_bucket_name  = "backup-compliance-reports"
      s3_key_prefix   = "monthly-reports/"
      report_template = "BACKUP_COMPLIANCE_REPORT"

      # Generate monthly reports
      accounts = [data.aws_caller_identity.current.account_id]
      regions  = ["us-east-1", "us-west-2"]
    }
  ]
}
```

### 3. Audit Framework

**AWS Backup Audit Manager**
```hcl
module "backup" {
  source = "lgallard/backup/aws"

  audit_framework = {
    create      = true
    name        = "backup-compliance-framework"
    description = "Comprehensive backup compliance framework"

    controls = [
      {
        name           = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name = "requiredRetentionDays"
        parameter_value = "30"
      },
      {
        name           = "BACKUP_RECOVERY_POINT_ENCRYPTED"
      },
      {
        name           = "BACKUP_VAULT_ENCRYPTED"
      },
      {
        name           = "BACKUP_VAULT_LOCK_ENABLED"
      }
    ]
  }
}
```

## Disaster Recovery

### 1. Cross-Region Backup Strategy

**Multi-Region Backup Setup**
```hcl
# Primary region backup
module "backup_primary" {
  source = "lgallard/backup/aws"

  providers = {
    aws = aws.primary
  }

  vault_name = "primary-backup-vault"

  rules = [
    {
      name = "cross_region_backup"
      schedule = "cron(0 2 * * ? *)"

      # Copy to secondary region
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-west-2:${data.aws_caller_identity.current.account_id}:backup-vault:disaster-recovery-vault"
          lifecycle = {
            delete_after = 90
          }
        }
      ]

      lifecycle = {
        delete_after = 30
      }
    }
  ]
}

# Secondary region backup vault
module "backup_secondary" {
  source = "lgallard/backup/aws"

  providers = {
    aws = aws.secondary
  }

  vault_name = "disaster-recovery-vault"
  vault_kms_key_arn = aws_kms_key.backup_dr.arn
}
```

### 2. Recovery Testing

**Automated Recovery Testing**
```hcl
# Create test restoration schedule
resource "aws_backup_restore_testing_plan" "main" {
  name                         = "backup-recovery-testing"
  schedule_expression          = "cron(0 6 ? * SUN *)"  # Weekly testing
  schedule_expression_timezone = "UTC"

  recovery_point_selection {
    algorithm = "LATEST_WITHIN_WINDOW"
    include_vaults = [module.backup.backup_vault_name]

    lookup_statuses = [
      "COMPLETED"
    ]
  }
}
```

### 3. RTO/RPO Optimization

**Recovery Time/Point Objectives**
```hcl
# Critical systems: Low RTO/RPO
critical_backup_rules = [
  {
    name                     = "critical_backup"
    schedule                 = "cron(0 */4 * * ? *)"  # Every 4 hours
    enable_continuous_backup = true                    # For supported services
    lifecycle = {
      delete_after = 90
    }
  }
]

# Standard systems: Medium RTO/RPO
standard_backup_rules = [
  {
    name     = "standard_backup"
    schedule = "cron(0 2 * * ? *)"  # Daily
    lifecycle = {
      delete_after = 30
    }
  }
]
```

## Operational Excellence

### 1. Infrastructure as Code

**Modular Backup Configuration**
```hcl
# Environment-specific configurations
module "backup_production" {
  source = "lgallard/backup/aws"

  vault_name = "prod-backup-vault"
  locked     = true

  plans = var.production_backup_plans

  tags = merge(var.common_tags, {
    Environment = "production"
  })
}

module "backup_staging" {
  source = "lgallard/backup/aws"

  vault_name = "staging-backup-vault"

  plans = var.staging_backup_plans

  tags = merge(var.common_tags, {
    Environment = "staging"
  })
}
```

### 2. Backup Validation

**Automated Backup Validation**
```hcl
# Lambda function for backup validation
resource "aws_lambda_function" "backup_validator" {
  filename         = "backup-validator.zip"
  function_name    = "backup-validator"
  role            = aws_iam_role.backup_validator.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      BACKUP_VAULT_NAME = module.backup.backup_vault_name
    }
  }
}

# CloudWatch Event Rule for validation
resource "aws_cloudwatch_event_rule" "backup_validation" {
  name        = "backup-validation-rule"
  description = "Trigger backup validation after backup completion"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["COMPLETED"]
    }
  })
}
```

### 3. Cost Optimization Automation

**Automated Cost Optimization**
```hcl
# Lambda function for cost optimization
resource "aws_lambda_function" "backup_cost_optimizer" {
  filename         = "backup-cost-optimizer.zip"
  function_name    = "backup-cost-optimizer"
  role            = aws_iam_role.backup_cost_optimizer.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900

  environment {
    variables = {
      BACKUP_VAULT_NAME = module.backup.backup_vault_name
      COST_THRESHOLD    = "1000"  # Monthly cost threshold in USD
    }
  }
}

# Scheduled cost optimization
resource "aws_cloudwatch_event_rule" "cost_optimization" {
  name                = "backup-cost-optimization"
  description         = "Monthly backup cost optimization"
  schedule_expression = "cron(0 6 1 * ? *)"  # First day of month
}
```

## Quick Reference

### Common Patterns

#### Daily Backup with Weekly Retention
```hcl
rules = [
  {
    name     = "daily_backup"
    schedule = "cron(0 2 * * ? *)"
    lifecycle = {
      delete_after = 7
    }
  }
]
```

#### Monthly Archive with Long Retention
```hcl
rules = [
  {
    name     = "monthly_archive"
    schedule = "cron(0 2 1 * ? *)"
    lifecycle = {
      cold_storage_after = 30
      delete_after       = 2555
    }
  }
]
```

#### Cross-Region Disaster Recovery
```hcl
rules = [
  {
    name = "disaster_recovery"
    schedule = "cron(0 2 * * ? *)"
    copy_actions = [
      {
        destination_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
        lifecycle = {
          delete_after = 90
        }
      }
    ]
  }
]
```

### Resource Selection Patterns

#### Tag-Based Selection
```hcl
selections = {
  "production-resources" = {
    selection_tags = [
      {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "production"
      },
      {
        type  = "STRINGEQUALS"
        key   = "BackupRequired"
        value = "true"
      }
    ]
  }
}
```

#### Service-Specific Selection
```hcl
selections = {
  "rds-databases" = {
    resources = [
      "arn:aws:rds:*:*:db:*"
    ]
  },
  "ec2-volumes" = {
    resources = [
      "arn:aws:ec2:*:*:volume/*"
    ]
  }
}
```

## Related Documentation

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting guide
- [PERFORMANCE.md](PERFORMANCE.md) - Performance optimization
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Known issues and solutions
- [MIGRATION.md](MIGRATION.md) - Migration guide
