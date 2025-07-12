# Cost-Optimized Backup Example
# This example demonstrates cost optimization strategies for AWS Backup
# including intelligent tiering, appropriate retention, and resource prioritization.

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
          schedule          = var.critical_backup_schedule
          start_window      = 60
          completion_window = 180
          lifecycle = {
            cold_storage_after = var.critical_cold_storage_days # Quick transition to save costs
            delete_after       = var.critical_retention_days
          }
          recovery_point_tags = {
            CostTier     = "Critical"
            DataClass    = "Tier1"
            Environment  = var.environment
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

    # Tier 2: Standard data - Balanced approach
    standard_tier = {
      name = "standard-cost-optimized"
      rules = [
        {
          name              = "standard-balanced-backup"
          schedule          = var.standard_backup_schedule
          start_window      = 120
          completion_window = 240
          lifecycle = {
            cold_storage_after = var.standard_cold_storage_days
            delete_after       = var.standard_retention_days
          }
          recovery_point_tags = {
            CostTier     = "Standard"
            DataClass    = "Tier2"
            Environment  = var.environment
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

    # Tier 3: Archive data - Long-term, infrequent access
    archive_tier = {
      name = "archive-cost-optimized"
      rules = [
        {
          name              = "archive-longterm-backup"
          schedule          = var.archive_backup_schedule
          start_window      = 180
          completion_window = 360
          lifecycle = {
            cold_storage_after = var.archive_cold_storage_days
            delete_after       = var.archive_retention_days
          }
          recovery_point_tags = {
            CostTier     = "Archive"
            DataClass    = "Tier3"
            Environment  = var.environment
            CostOptimized = "true"
            Purpose      = "LongTermArchive"
          }
        }
      ]
      selections = {
        archive_resources = {
          resources = var.archive_resources
          selection_tags = [
            {
              type  = "STRINGEQUALS"
              key   = "CostTier"
              value = "Archive"
            }
          ]
        }
      }
    }

    # Tier 4: Development - Minimal cost, short retention
    development_tier = {
      name = "development-minimal-cost"
      rules = [
        {
          name              = "development-weekly-backup"
          schedule          = var.development_backup_schedule
          start_window      = 240
          completion_window = 480
          lifecycle = {
            cold_storage_after = 0 # No cold storage for dev to minimize costs
            delete_after       = var.development_retention_days
          }
          recovery_point_tags = {
            CostTier     = "Development"
            DataClass    = "Tier4"
            Environment  = "development"
            CostOptimized = "true"
            Purpose      = "Development"
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
            },
            {
              type  = "STRINGEQUALS"
              key   = "CostTier"
              value = "Development"
            }
          ]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Purpose       = "CostOptimizedBackup"
    CostStrategy  = "MultiTier"
  })
}

# Cost monitoring dashboard
resource "aws_cloudwatch_dashboard" "cost_optimization" {
  count = var.enable_cost_monitoring ? 1 : 0

  dashboard_name = "${var.vault_name}-cost-optimization"

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
            ["AWS/Backup", "NumberOfRecoveryPointsCreated", "BackupVaultName", var.vault_name]
          ]
          period = 86400
          stat   = "Sum"
          region = var.region
          title  = "Backup Activity (Cost Impact)"
          view   = "timeSeries"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 12
        height = 3
        properties = {
          markdown = <<-EOT
## Cost Optimization Strategy

### Tier 1 - Critical (${length(var.critical_resources)} resources)
- **Frequency**: ${var.critical_backup_schedule}
- **Retention**: ${var.critical_retention_days} days
- **Cold Storage**: ${var.critical_cold_storage_days} days
- **Estimated Cost**: $${var.critical_estimated_monthly_cost}/month

### Tier 2 - Standard (${length(var.standard_resources)} resources)  
- **Frequency**: ${var.standard_backup_schedule}
- **Retention**: ${var.standard_retention_days} days
- **Cold Storage**: ${var.standard_cold_storage_days} days
- **Estimated Cost**: $${var.standard_estimated_monthly_cost}/month

### Tier 3 - Archive (${length(var.archive_resources)} resources)
- **Frequency**: ${var.archive_backup_schedule}
- **Retention**: ${var.archive_retention_days} days
- **Cold Storage**: ${var.archive_cold_storage_days} days
- **Estimated Cost**: $${var.archive_estimated_monthly_cost}/month

### Tier 4 - Development (${length(var.development_resources)} resources)
- **Frequency**: ${var.development_backup_schedule}
- **Retention**: ${var.development_retention_days} days
- **Cold Storage**: Disabled
- **Estimated Cost**: $${var.development_estimated_monthly_cost}/month

**Total Estimated Monthly Cost**: $${var.critical_estimated_monthly_cost + var.standard_estimated_monthly_cost + var.archive_estimated_monthly_cost + var.development_estimated_monthly_cost}
EOT
        }
      }
    ]
  })

  tags = var.tags
}

# Cost budget alert
resource "aws_budgets_budget" "backup_cost_budget" {
  count = var.enable_cost_budget ? 1 : 0

  name         = "${var.vault_name}-backup-cost-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_cost_budget
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters = {
    Service = ["Amazon Simple Storage Service", "AWS Backup"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.budget_notification_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_notification_emails
  }

  tags = var.tags
}

# Lambda function for cost optimization recommendations
resource "aws_lambda_function" "cost_optimizer" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  filename         = "cost_optimizer.zip"
  function_name    = "${var.vault_name}-cost-optimizer"
  role            = aws_iam_role.cost_optimizer_role[0].arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.cost_optimizer_zip[0].output_base64sha256
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      VAULT_NAME = var.vault_name
      SNS_TOPIC  = var.cost_alert_sns_topic_arn
    }
  }

  tags = var.tags
}

data "archive_file" "cost_optimizer_zip" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  type        = "zip"
  output_path = "cost_optimizer.zip"
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
    
    recommendations = []
    
    try:
        # Analyze recovery points for cost optimization
        response = backup_client.list_recovery_points(BackupVaultName=vault_name)
        
        old_recovery_points = []
        total_size = 0
        
        for rp in response['RecoveryPoints']:
            created_date = rp['CreationDate'].replace(tzinfo=None)
            age_days = (datetime.now() - created_date).days
            
            if age_days > 90 and rp.get('StorageClass') != 'COLD':
                old_recovery_points.append({
                    'arn': rp['RecoveryPointArn'],
                    'age_days': age_days,
                    'size': rp.get('BackupSizeInBytes', 0)
                })
            
            total_size += rp.get('BackupSizeInBytes', 0)
        
        # Generate recommendations
        if old_recovery_points:
            total_old_size = sum(rp['size'] for rp in old_recovery_points)
            potential_savings = total_old_size * 0.004 * 30 / (1024**3)  # Rough S3 cost difference
            
            recommendations.append({
                'type': 'cold_storage_transition',
                'description': f'Move {len(old_recovery_points)} recovery points to cold storage',
                'potential_monthly_savings': f'${potential_savings:.2f}',
                'recovery_points': len(old_recovery_points)
            })
        
        # Check for unused recovery points (no restore jobs)
        # Add more cost optimization logic here
        
        if recommendations and sns_topic:
            message = json.dumps({
                'vault': vault_name,
                'recommendations': recommendations,
                'total_recovery_points': len(response['RecoveryPoints']),
                'total_size_gb': total_size / (1024**3)
            }, indent=2)
            
            sns_client.publish(
                TopicArn=sns_topic,
                Message=message,
                Subject=f"Backup Cost Optimization Recommendations for {vault_name}"
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'recommendations': recommendations,
                'vault': vault_name
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

resource "aws_iam_role" "cost_optimizer_role" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  name = "${var.vault_name}-cost-optimizer-role"

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

resource "aws_iam_role_policy" "cost_optimizer_policy" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  name = "${var.vault_name}-cost-optimizer-policy"
  role = aws_iam_role.cost_optimizer_role[0].id

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
          "backup:ListRecoveryPoints",
          "backup:DescribeRecoveryPoint",
          "backup:ListRestoreJobs"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.cost_alert_sns_topic_arn != null ? var.cost_alert_sns_topic_arn : "*"
      }
    ]
  })
}

# Schedule weekly cost optimization analysis
resource "aws_cloudwatch_event_rule" "weekly_cost_analysis" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  name                = "${var.vault_name}-weekly-cost-analysis"
  description         = "Weekly backup cost optimization analysis"
  schedule_expression = "cron(0 9 ? * SUN *)" # Sunday at 9 AM

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cost_optimizer_target" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  rule      = aws_cloudwatch_event_rule.weekly_cost_analysis[0].name
  target_id = "TriggerCostOptimizer"
  arn       = aws_lambda_function.cost_optimizer[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_cost_optimizer" {
  count = var.enable_cost_optimization_lambda ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_cost_analysis[0].arn
}