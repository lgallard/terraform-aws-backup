# Performance Optimization Guide

This guide provides detailed recommendations for optimizing AWS Backup performance when using the terraform-aws-backup module.

## Table of Contents

- [Performance Fundamentals](#performance-fundamentals)
- [Backup Window Optimization](#backup-window-optimization)
- [Service-Specific Performance](#service-specific-performance)
- [Scheduling Optimization](#scheduling-optimization)
- [Network and Bandwidth](#network-and-bandwidth)
- [Monitoring and Metrics](#monitoring-and-metrics)
- [Troubleshooting Performance Issues](#troubleshooting-performance-issues)
- [Cost vs Performance Trade-offs](#cost-vs-performance-trade-offs)

## Performance Fundamentals

### Understanding Backup Performance Factors

1. **Resource Size**: Larger resources take longer to backup
2. **Change Rate**: Higher change rates require more time for incremental backups
3. **Network Bandwidth**: Available bandwidth affects backup speed
4. **Backup Window**: Time allocated for backup operations
5. **Concurrent Operations**: Number of simultaneous backup jobs
6. **Storage Type**: Different storage types have different performance characteristics

### Performance Metrics

Key metrics to monitor:
- **Backup Job Duration**: Time taken to complete backup jobs
- **Backup Job Success Rate**: Percentage of successful backups
- **Recovery Point Objective (RPO)**: Maximum acceptable data loss
- **Recovery Time Objective (RTO)**: Maximum acceptable downtime
- **Throughput**: Data transfer rate during backup operations

## Backup Window Optimization

### Calculating Optimal Backup Windows

**Formula for Backup Window Sizing:**
```
Backup Window = (Data Size / Throughput) + (Overhead × Safety Factor)
```

**Example Calculations:**
```hcl
# Small resources (< 1GB)
locals {
  small_resource_window = {
    start_window      = 60    # 1 hour
    completion_window = 180   # 3 hours
  }
}

# Medium resources (1-100GB)  
locals {
  medium_resource_window = {
    start_window      = 120   # 2 hours
    completion_window = 480   # 8 hours
  }
}

# Large resources (> 100GB)
locals {
  large_resource_window = {
    start_window      = 240   # 4 hours
    completion_window = 1440  # 24 hours
  }
}

# Very large resources (> 1TB)
locals {
  xlarge_resource_window = {
    start_window      = 360   # 6 hours
    completion_window = 2880  # 48 hours
  }
}
```

### Dynamic Window Configuration

**Size-Based Rule Configuration:**
```hcl
# Define backup rules based on resource size
variable "backup_rules_by_size" {
  description = "Backup rules optimized by resource size"
  type = map(object({
    schedule          = string
    start_window      = number
    completion_window = number
    lifecycle = object({
      cold_storage_after = optional(number)
      delete_after       = number
    })
  }))
  
  default = {
    "small" = {
      schedule          = "cron(0 2 * * ? *)"
      start_window      = 60
      completion_window = 180
      lifecycle = {
        delete_after = 30
      }
    }
    "medium" = {
      schedule          = "cron(0 1 * * ? *)"
      start_window      = 120
      completion_window = 480
      lifecycle = {
        delete_after = 30
      }
    }
    "large" = {
      schedule          = "cron(0 0 * * ? *)"
      start_window      = 240
      completion_window = 1440
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 90
      }
    }
  }
}
```

## Service-Specific Performance

### Amazon EFS Performance Optimization

**EFS Backup Performance Factors:**
- File system size
- Number of files
- Performance mode (General Purpose vs Max I/O)
- Throughput mode (Provisioned vs Bursting)

**EFS Optimization Configuration:**
```hcl
# Large EFS systems require extended windows
rules = [
  {
    name              = "efs_large_backup"
    schedule          = "cron(0 22 * * ? *)"   # Start at 10 PM
    start_window      = 240                     # 4 hours to start
    completion_window = 2880                    # 48 hours to complete
    lifecycle = {
      cold_storage_after = 30
      delete_after       = 365
    }
  }
]

# EFS with many small files
rules = [
  {
    name              = "efs_many_files_backup"
    schedule          = "cron(0 20 * * ? *)"   # Start at 8 PM
    start_window      = 360                     # 6 hours to start
    completion_window = 2880                    # 48 hours to complete
    lifecycle = {
      delete_after = 90
    }
  }
]
```

**EFS Performance Monitoring:**
```hcl
# CloudWatch alarm for EFS backup duration
resource "aws_cloudwatch_metric_alarm" "efs_backup_duration" {
  alarm_name          = "efs-backup-duration-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BackupJobDuration"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Average"
  threshold           = "28800"  # 8 hours in seconds
  alarm_description   = "EFS backup taking too long"
  
  dimensions = {
    ResourceType = "EFS"
  }
}
```

### Amazon RDS Performance Optimization

**RDS Backup Performance Factors:**
- Database size
- Transaction log activity
- Storage type (gp2, gp3, io1, io2)
- Multi-AZ configuration
- Read replicas

**RDS Optimization Configuration:**
```hcl
# RDS backup optimization
rules = [
  {
    name              = "rds_optimized_backup"
    schedule          = "cron(0 3 * * ? *)"   # After automated backups
    start_window      = 60                     # 1 hour
    completion_window = 240                    # 4 hours
    lifecycle = {
      delete_after = 7  # Short retention for frequent backups
    }
  }
]

# Large RDS instances
rules = [
  {
    name              = "rds_large_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 120
    completion_window = 480
    lifecycle = {
      delete_after = 30
    }
  }
]
```

**RDS Performance Best Practices:**
```hcl
# Coordinate with RDS maintenance windows
locals {
  rds_backup_schedule = {
    # If RDS maintenance window is Sunday 03:00-04:00 UTC
    # Schedule backups after maintenance
    schedule = "cron(0 5 ? * SUN *)"  # Sunday 5 AM UTC
  }
}
```

### Amazon DynamoDB Performance Optimization

**DynamoDB Backup Performance Factors:**
- Table size
- Read/write capacity units
- Global secondary indexes
- Point-in-time recovery settings

**DynamoDB Optimization Configuration:**
```hcl
# DynamoDB backup optimization
rules = [
  {
    name                     = "dynamodb_backup"
    schedule                 = "cron(0 2 * * ? *)"
    start_window             = 30   # DynamoDB backups are fast
    completion_window        = 120  # Usually complete quickly
    enable_continuous_backup = true # For PITR-enabled tables
    lifecycle = {
      delete_after = 35  # Keep point-in-time recovery for 35 days
    }
  }
]

# Large DynamoDB tables
rules = [
  {
    name              = "dynamodb_large_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 60
    completion_window = 240
    lifecycle = {
      delete_after = 30
    }
  }
]
```

### Amazon EC2 Performance Optimization

**EC2 Backup Performance Factors:**
- Volume size
- Volume type (gp2, gp3, io1, io2)
- Instance type
- Application activity during backup

**EC2 Optimization Configuration:**
```hcl
# EC2 volume backup optimization
rules = [
  {
    name              = "ec2_volume_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 120  # 2 hours
    completion_window = 480  # 8 hours
    lifecycle = {
      delete_after = 30
    }
  }
]

# High-performance volumes
rules = [
  {
    name              = "ec2_high_perf_backup"
    schedule          = "cron(0 1 * * ? *)"
    start_window      = 180
    completion_window = 720
    lifecycle = {
      delete_after = 30
    }
  }
]
```

**EC2 Performance Monitoring:**
```hcl
# Monitor EC2 backup performance
resource "aws_cloudwatch_metric_alarm" "ec2_backup_performance" {
  alarm_name          = "ec2-backup-slow"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BackupJobDuration"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Average"
  threshold           = "7200"  # 2 hours
  alarm_description   = "EC2 backup taking longer than expected"
  
  dimensions = {
    ResourceType = "EC2"
  }
}
```

## Scheduling Optimization

### Optimal Scheduling Strategies

**Time Zone Considerations:**
```hcl
# Schedule backups during off-peak hours
locals {
  backup_schedules = {
    # US East Coast (EST/EDT)
    us_east = {
      daily   = "cron(0 2 * * ? *)"   # 2 AM EST
      weekly  = "cron(0 1 ? * SUN *)" # Sunday 1 AM EST
      monthly = "cron(0 0 1 * ? *)"   # 1st of month 12 AM EST
    }
    
    # US West Coast (PST/PDT)
    us_west = {
      daily   = "cron(0 5 * * ? *)"   # 2 AM PST (5 AM UTC)
      weekly  = "cron(0 4 ? * SUN *)" # Sunday 1 AM PST
      monthly = "cron(0 3 1 * ? *)"   # 1st of month 12 AM PST
    }
    
    # Europe (CET/CEST)
    europe = {
      daily   = "cron(0 1 * * ? *)"   # 2 AM CET (1 AM UTC)
      weekly  = "cron(0 0 ? * SUN *)" # Sunday 1 AM CET
      monthly = "cron(0 23 1 * ? *)"  # 1st of month 12 AM CET
    }
  }
}
```

**Staggered Scheduling:**
```hcl
# Stagger backups to avoid resource contention
plans = {
  "critical-tier-1" = {
    rules = [
      {
        name     = "tier1_backup"
        schedule = "cron(0 1 * * ? *)"  # 1 AM
        lifecycle = {
          delete_after = 30
        }
      }
    ]
  }
  
  "critical-tier-2" = {
    rules = [
      {
        name     = "tier2_backup"
        schedule = "cron(0 2 * * ? *)"  # 2 AM
        lifecycle = {
          delete_after = 30
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

### Frequency Optimization

**Backup Frequency by Data Criticality:**
```hcl
# Mission-critical: Multiple backups per day
variable "critical_backup_rules" {
  default = [
    {
      name     = "critical_morning"
      schedule = "cron(0 6 * * ? *)"   # 6 AM
      lifecycle = {
        delete_after = 7
      }
    },
    {
      name     = "critical_afternoon"
      schedule = "cron(0 14 * * ? *)"  # 2 PM
      lifecycle = {
        delete_after = 7
      }
    },
    {
      name     = "critical_evening"
      schedule = "cron(0 22 * * ? *)"  # 10 PM
      lifecycle = {
        delete_after = 7
      }
    }
  ]
}

# Standard: Daily backups
variable "standard_backup_rules" {
  default = [
    {
      name     = "daily_backup"
      schedule = "cron(0 2 * * ? *)"
      lifecycle = {
        delete_after = 30
      }
    }
  ]
}

# Archive: Weekly backups
variable "archive_backup_rules" {
  default = [
    {
      name     = "weekly_backup"
      schedule = "cron(0 2 ? * SUN *)"
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
    }
  ]
}
```

## Network and Bandwidth

### Bandwidth Optimization

**Cross-Region Backup Considerations:**
```hcl
# Optimize cross-region backup timing
rules = [
  {
    name = "cross_region_backup"
    schedule = "cron(0 23 * * ? *)"  # Start late to avoid peak hours
    start_window = 120                # Extended start window
    completion_window = 720           # Extended completion window
    
    copy_actions = [
      {
        destination_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
        lifecycle = {
          delete_after = 30
        }
      }
    ]
  }
]
```

**Bandwidth Monitoring:**
```hcl
# Monitor cross-region data transfer
resource "aws_cloudwatch_metric_alarm" "cross_region_transfer" {
  alarm_name          = "cross-region-backup-slow"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CopyJobDuration"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Average"
  threshold           = "14400"  # 4 hours
  alarm_description   = "Cross-region backup taking too long"
}
```

### Network Optimization Strategies

**VPC Endpoint Configuration:**
```hcl
# VPC endpoint for AWS Backup (where supported)
resource "aws_vpc_endpoint" "backup" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.backup"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.backup_endpoint.id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "backup:*"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Monitoring and Metrics

### Performance Monitoring Dashboard

**CloudWatch Dashboard for Backup Performance:**
```hcl
resource "aws_cloudwatch_dashboard" "backup_performance" {
  dashboard_name = "backup-performance-dashboard"
  
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
            ["AWS/Backup", "NumberOfBackupJobsCompleted"],
            [".", "NumberOfBackupJobsFailed"],
            [".", "NumberOfBackupJobsExpired"]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
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
            ["AWS/Backup", "BackupJobDuration", "ResourceType", "EFS"],
            [".", ".", ".", "RDS"],
            [".", ".", ".", "EC2"],
            [".", ".", ".", "DynamoDB"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Backup Duration by Service"
        }
      }
    ]
  })
}
```

### Custom Performance Metrics

**Lambda Function for Custom Metrics:**
```hcl
resource "aws_lambda_function" "backup_performance_metrics" {
  filename         = "backup-performance-metrics.zip"
  function_name    = "backup-performance-metrics"
  role            = aws_iam_role.backup_metrics.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300
  
  environment {
    variables = {
      BACKUP_VAULT_NAME = var.backup_vault_name
      REGION           = var.region
    }
  }
}

# Schedule metrics collection
resource "aws_cloudwatch_event_rule" "backup_metrics" {
  name                = "backup-performance-metrics"
  description         = "Collect backup performance metrics"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "backup_metrics" {
  rule      = aws_cloudwatch_event_rule.backup_metrics.name
  target_id = "BackupMetricsTarget"
  arn       = aws_lambda_function.backup_performance_metrics.arn
}
```

### Performance Alerting

**Comprehensive Performance Alerts:**
```hcl
# Backup job duration alert
resource "aws_cloudwatch_metric_alarm" "backup_duration_high" {
  alarm_name          = "backup-duration-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BackupJobDuration"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Average"
  threshold           = "7200"  # 2 hours
  alarm_description   = "Backup job duration exceeded threshold"
  alarm_actions       = [aws_sns_topic.backup_alerts.arn]
}

# Backup job failure rate alert
resource "aws_cloudwatch_metric_alarm" "backup_failure_rate" {
  alarm_name          = "backup-failure-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BackupJobFailureRate"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"    # 10% failure rate
  alarm_description   = "Backup job failure rate exceeded threshold"
  alarm_actions       = [aws_sns_topic.backup_alerts.arn]
}
```

## Troubleshooting Performance Issues

### Common Performance Issues

#### 1. Backup Job Timeouts

**Problem:** Backup jobs exceeding completion window
**Solutions:**
```hcl
# Increase completion window
rules = [
  {
    name              = "extended_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 120
    completion_window = 1440  # Increase from 480 to 1440 minutes
    lifecycle = {
      delete_after = 30
    }
  }
]
```

#### 2. Slow EFS Backups

**Problem:** EFS backups taking longer than expected
**Solutions:**
```hcl
# Optimize EFS backup schedule
rules = [
  {
    name              = "efs_optimized"
    schedule          = "cron(0 20 * * ? *)"  # Start earlier
    start_window      = 240                    # 4 hours to start
    completion_window = 2880                   # 48 hours to complete
    lifecycle = {
      delete_after = 30
    }
  }
]
```

#### 3. RDS Backup Conflicts

**Problem:** RDS backups conflicting with automated backups
**Solutions:**
```hcl
# Coordinate with RDS automated backups
rules = [
  {
    name     = "rds_coordinated"
    schedule = "cron(0 4 * * ? *)"  # After automated backups
    start_window = 60
    completion_window = 240
    lifecycle = {
      delete_after = 7
    }
  }
]
```

### Performance Debugging

**Enable Debug Logging:**
```hcl
# CloudWatch Log Group for backup logs
resource "aws_cloudwatch_log_group" "backup_logs" {
  name              = "/aws/backup/performance"
  retention_in_days = 30
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "backup_performance" {
  name           = "backup-performance-stream"
  log_group_name = aws_cloudwatch_log_group.backup_logs.name
}
```

**Performance Analysis Queries:**
```sql
-- CloudWatch Insights queries for performance analysis

-- Average backup duration by service
fields @timestamp, @message
| filter @message like /BACKUP_JOB_COMPLETED/
| stats avg(duration) by ResourceType

-- Backup job failure analysis
fields @timestamp, @message
| filter @message like /BACKUP_JOB_FAILED/
| stats count() by FailureReason

-- Cross-region backup performance
fields @timestamp, @message
| filter @message like /COPY_JOB/
| stats avg(duration) by SourceRegion, DestinationRegion
```

## Cost vs Performance Trade-offs

### Performance vs Cost Analysis

**High Performance Configuration:**
```hcl
# High performance, higher cost
rules = [
  {
    name              = "high_performance"
    schedule          = "cron(0 */6 * * ? *)"  # Every 6 hours
    start_window      = 30                      # Quick start
    completion_window = 240                     # 4 hours max
    lifecycle = {
      delete_after = 30  # Frequent backups, shorter retention
    }
  }
]
```

**Cost Optimized Configuration:**
```hcl
# Cost optimized, acceptable performance
rules = [
  {
    name              = "cost_optimized"
    schedule          = "cron(0 2 ? * SUN *)"  # Weekly backups
    start_window      = 120                     # Extended start window
    completion_window = 720                     # Extended completion window
    lifecycle = {
      cold_storage_after = 30   # Move to cold storage
      delete_after       = 365  # Long retention
    }
  }
]
```

### Performance Tuning Recommendations

**By Resource Type:**

| Resource Type | Recommended Start Window | Recommended Completion Window | Optimal Schedule |
|---------------|-------------------------|------------------------------|------------------|
| DynamoDB      | 30 minutes              | 120 minutes                  | Every 4-6 hours  |
| RDS (Small)   | 60 minutes              | 240 minutes                  | Daily            |
| RDS (Large)   | 120 minutes             | 480 minutes                  | Daily            |
| EC2 Volumes   | 60 minutes              | 240 minutes                  | Daily            |
| EFS (Small)   | 120 minutes             | 480 minutes                  | Daily            |
| EFS (Large)   | 240 minutes             | 2880 minutes                 | Daily            |

**By Criticality:**

| Criticality Level | Backup Frequency | Retention Period | Performance Priority |
|------------------|------------------|------------------|---------------------|
| Mission Critical | Every 4 hours    | 30 days          | High                |
| Business Critical| Daily            | 30 days          | Medium              |
| Standard         | Daily            | 14 days          | Medium              |
| Archive          | Weekly           | 365 days         | Low                 |

## Quick Reference

### Performance Optimization Checklist

- [ ] Set appropriate backup windows based on resource size
- [ ] Stagger backup schedules to avoid resource contention
- [ ] Monitor backup job duration and success rates
- [ ] Optimize schedules for different time zones
- [ ] Configure service-specific optimizations
- [ ] Set up performance alerting
- [ ] Regularly review and adjust configurations
- [ ] Test backup and restore performance
- [ ] Monitor costs vs performance trade-offs

### Common Performance Patterns

```hcl
# Small, frequent backups
small_frequent = {
  schedule          = "cron(0 */4 * * ? *)"
  start_window      = 30
  completion_window = 120
  lifecycle = {
    delete_after = 7
  }
}

# Large, infrequent backups
large_infrequent = {
  schedule          = "cron(0 2 ? * SUN *)"
  start_window      = 240
  completion_window = 1440
  lifecycle = {
    cold_storage_after = 30
    delete_after       = 365
  }
}

# Cross-region with extended windows
cross_region = {
  schedule          = "cron(0 23 * * ? *)"
  start_window      = 120
  completion_window = 720
  copy_actions = [
    {
      destination_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
      lifecycle = {
        delete_after = 90
      }
    }
  ]
}
```

## Related Documentation

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Troubleshooting guide
- [BEST_PRACTICES.md](BEST_PRACTICES.md) - Best practices guide
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Known issues and solutions
- [AWS Backup Performance Documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/backup-performance.html)