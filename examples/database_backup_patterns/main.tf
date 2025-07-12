# Database-Specific Backup Patterns Example
# This example demonstrates optimized backup strategies for different database types
# including RDS, DynamoDB, DocumentDB, and Aurora clusters.

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

# Multiple backup plans optimized for different database workloads
module "database_backup_patterns" {
  source = "../.."

  vault_name        = var.vault_name
  vault_kms_key_arn = var.vault_kms_key_arn

  # Use the new plans format for multiple backup strategies
  plans = {
    # Critical production databases - High frequency backups
    critical_databases = {
      name = "critical-database-backup"
      rules = [
        {
          name                     = "critical-continuous-backup"
          schedule                 = "cron(0 */6 * * ? *)" # Every 6 hours
          start_window             = 60
          completion_window        = 240 # 4 hours for large databases
          enable_continuous_backup = true # Point-in-time recovery
          lifecycle = {
            cold_storage_after = 7   # Move to cold storage after 7 days
            delete_after       = 90  # Keep for 90 days
          }
          recovery_point_tags = {
            DatabaseTier = "Critical"
            Frequency    = "Continuous"
            Environment  = var.environment
          }
        }
      ]
      selections = {
        critical_databases = {
          resources = [
            "arn:aws:rds:*:*:db:prod-*",
            "arn:aws:rds:*:*:cluster:prod-*"
          ]
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "DatabaseTier"
              value = "Critical"
            },
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = var.environment
            }
          ]
        }
      }
    }

    # Standard production databases - Daily backups
    standard_databases = {
      name = "standard-database-backup"
      rules = [
        {
          name              = "standard-daily-backup"
          schedule          = "cron(0 3 * * ? *)" # 3 AM daily
          start_window      = 120
          completion_window = 360 # 6 hours
          lifecycle = {
            cold_storage_after = 30  # Move to cold storage after 30 days
            delete_after       = 180 # Keep for 6 months
          }
          recovery_point_tags = {
            DatabaseTier = "Standard"
            Frequency    = "Daily"
            Environment  = var.environment
          }
        }
      ]
      selections = {
        standard_databases = {
          resources = concat(
            var.standard_rds_resources,
            var.dynamodb_resources
          )
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "DatabaseTier"
              value = "Standard"
            },
            {
              type  = "STRINGEQUALS"
              key   = "BackupRequired"
              value = "true"
            }
          ]
        }
      }
    }

    # Development databases - Weekly backups
    development_databases = {
      name = "development-database-backup"
      rules = [
        {
          name              = "development-weekly-backup"
          schedule          = "cron(0 1 ? * SUN *)" # Weekly on Sunday at 1 AM
          start_window      = 180
          completion_window = 480
          lifecycle = {
            cold_storage_after = 0  # No cold storage for dev
            delete_after       = 30 # Keep for 30 days only
          }
          recovery_point_tags = {
            DatabaseTier = "Development"
            Frequency    = "Weekly"
            Environment  = var.environment
          }
        }
      ]
      selections = {
        development_databases = {
          resources = var.development_db_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Environment"
              value = "development"
            },
            {
              type  = "STRINGEQUALS"
              key   = "BackupRequired"
              value = "true"
            }
          ]
        }
      }
    }

    # DynamoDB specific backup strategy
    dynamodb_backup = {
      name = "dynamodb-backup-strategy"
      rules = [
        {
          name              = "dynamodb-daily-backup"
          schedule          = "cron(0 4 * * ? *)" # 4 AM daily
          start_window      = 60
          completion_window = 180 # DynamoDB backups are typically faster
          lifecycle = {
            cold_storage_after = 90  # DynamoDB benefits from longer warm storage
            delete_after       = 365 # Keep for 1 year for analytics
          }
          recovery_point_tags = {
            DatabaseType = "DynamoDB"
            Frequency    = "Daily"
            Purpose      = "Analytics"
          }
        }
      ]
      selections = {
        dynamodb_tables = {
          resources = var.dynamodb_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "Service"
              value = "DynamoDB"
            }
          ]
        }
      }
    }
  }

  # Global settings
  tags = merge(var.tags, {
    Purpose = "DatabaseBackup"
    Module  = "terraform-aws-backup"
  })
}

# Optional: Enhanced monitoring and alerting for database backups
resource "aws_cloudwatch_metric_alarm" "backup_failure_alarm" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.vault_name}-backup-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup job failures"
  alarm_actions       = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    BackupVaultName = var.vault_name
  }

  tags = var.tags
}

# Optional: Lambda function for backup validation
resource "aws_lambda_function" "backup_validator" {
  count = var.enable_backup_validation ? 1 : 0

  filename         = "backup_validator.zip"
  function_name    = "${var.vault_name}-backup-validator"
  role            = aws_iam_role.lambda_role[0].arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      VAULT_NAME = var.vault_name
      SNS_TOPIC  = var.alarm_sns_topic_arn
    }
  }

  tags = var.tags
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  count = var.enable_backup_validation ? 1 : 0

  type        = "zip"
  output_path = "backup_validator.zip"
  source {
    content = <<EOF
import json
import boto3
import os
from datetime import datetime, timedelta

def handler(event, context):
    backup_client = boto3.client('backup')
    sns_client = boto3.client('sns')
    
    vault_name = os.environ['VAULT_NAME']
    sns_topic = os.environ.get('SNS_TOPIC')
    
    # Check for backup jobs in the last 24 hours
    yesterday = datetime.now() - timedelta(days=1)
    
    try:
        response = backup_client.list_backup_jobs(
            ByBackupVaultName=vault_name,
            ByCreatedAfter=yesterday
        )
        
        failed_jobs = [job for job in response['BackupJobs'] if job['State'] == 'FAILED']
        
        if failed_jobs and sns_topic:
            message = f"Found {len(failed_jobs)} failed backup jobs in vault {vault_name}"
            sns_client.publish(
                TopicArn=sns_topic,
                Message=message,
                Subject="Database Backup Failure Alert"
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'total_jobs': len(response['BackupJobs']),
                'failed_jobs': len(failed_jobs)
            })
        }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
EOF
    filename = "index.py"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  count = var.enable_backup_validation ? 1 : 0

  name = "${var.vault_name}-backup-validator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  count = var.enable_backup_validation ? 1 : 0

  name = "${var.vault_name}-backup-validator-policy"
  role = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "backup:ListBackupJobs",
          "backup:DescribeBackupJob"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : "*"
      }
    ]
  })
}

# CloudWatch event rule to trigger validation
resource "aws_cloudwatch_event_rule" "daily_validation" {
  count = var.enable_backup_validation ? 1 : 0

  name                = "${var.vault_name}-daily-backup-validation"
  description         = "Trigger backup validation daily"
  schedule_expression = "cron(0 8 * * ? *)" # 8 AM daily

  tags = var.tags
}

# CloudWatch event target
resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.enable_backup_validation ? 1 : 0

  rule      = aws_cloudwatch_event_rule.daily_validation[0].name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.backup_validator[0].arn
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_backup_validation ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_validator[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_validation[0].arn
}