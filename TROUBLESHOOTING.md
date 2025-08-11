# Troubleshooting Guide

This guide provides detailed troubleshooting steps for common issues when using the terraform-aws-backup module.

## Table of Contents
- [General Troubleshooting](#general-troubleshooting)
- [Authentication & Permissions](#authentication--permissions)
- [Resource Creation Issues](#resource-creation-issues)
- [Backup Job Failures](#backup-job-failures)
- [Cross-Region Backup Issues](#cross-region-backup-issues)
- [Performance Issues](#performance-issues)
- [Monitoring & Logging](#monitoring--logging)
- [Common Error Messages](#common-error-messages)

## General Troubleshooting

### Step 1: Enable Debug Logging
Always start troubleshooting with detailed logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform plan
terraform apply
```

### Step 2: Check AWS Service Health
Before deep troubleshooting, check:
- [AWS Service Health Dashboard](https://health.aws.amazon.com/health/status)
- AWS Backup service status in your region
- Any ongoing maintenance or outages

### Step 3: Verify Region Support
Ensure AWS Backup is available in your target region:
- Check [AWS Regional Services](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/)
- Verify cross-region backup support if applicable

## Authentication & Permissions

### Access Denied Errors

#### Problem
```
Error: AccessDeniedException: User: arn:aws:iam::123456789012:user/username is not authorized to perform: backup:CreateBackupVault
```

#### Troubleshooting Steps

1. **Check IAM Policy**
   ```bash
   aws iam get-user-policy --user-name username --policy-name policy-name
   ```

2. **Verify Required Permissions**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "backup:*",
           "iam:CreateRole",
           "iam:AttachRolePolicy",
           "iam:PutRolePolicy",
           "iam:PassRole",
           "kms:CreateGrant",
           "kms:DescribeKey",
           "organizations:DescribeOrganization"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

3. **Check Service-Linked Role**
   ```bash
   aws iam get-role --role-name AWSBackupDefaultServiceRole
   ```

   If missing, create it:
   ```bash
   aws iam create-service-linked-role --aws-service-name backup.amazonaws.com
   ```

### Cross-Account Access Issues

#### Problem
```
Error: AccessDeniedException: Cross account access denied
```

#### Troubleshooting Steps

1. **Verify Cross-Account Trust Policy**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::ACCOUNT-ID:root"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

2. **Check Resource-Based Policies**
   - KMS key policies
   - S3 bucket policies (for cross-region backups)
   - Vault access policies

## Resource Creation Issues

### Vault Creation Failures

#### Problem
```
Error creating Backup Vault: InvalidParameterValueException: Vault name already exists
```

#### Troubleshooting Steps

1. **Check Existing Vaults**
   ```bash
   aws backup list-backup-vaults
   ```

2. **Verify Vault Name Uniqueness**
   - Vault names must be unique within a region
   - Use the `vault_name` variable with a unique identifier

3. **Check Vault Lock Status**
   ```bash
   aws backup describe-backup-vault --backup-vault-name vault-name
   ```

### KMS Key Issues

#### Problem
```
Error: KMS key not found or access denied
```

#### Troubleshooting Steps

1. **Verify KMS Key Exists**
   ```bash
   aws kms describe-key --key-id arn:aws:kms:region:account:key/key-id
   ```

2. **Check Key Policy**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "backup.amazonaws.com"
         },
         "Action": [
           "kms:Encrypt",
           "kms:Decrypt",
           "kms:ReEncrypt*",
           "kms:GenerateDataKey*",
           "kms:DescribeKey"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

3. **Verify Cross-Region Key Access**
   For cross-region backups, ensure the KMS key policy allows access from both regions.

## Backup Job Failures

### Backup Job Status Monitoring

#### Check Job Status
```bash
aws backup list-backup-jobs --by-backup-vault-name vault-name
```

#### Common Job Failure Reasons

1. **Resource Not Found**
   - Verify the resource ARN is correct
   - Check if the resource was deleted after the backup plan was created

2. **Insufficient Permissions**
   - Verify the backup role has permissions to access the resource
   - Check service-specific backup permissions

3. **Resource Busy**
   - For RDS: Check if maintenance window conflicts with backup schedule
   - For EFS: Verify no concurrent backup operations

### Service-Specific Troubleshooting

#### RDS Backup Issues
```bash
# Check RDS automated backup settings
aws rds describe-db-instances --db-instance-identifier db-name

# Verify backup window doesn't conflict
aws backup describe-backup-plan --backup-plan-id plan-id
```

#### DynamoDB Backup Issues
```bash
# Check Point-in-Time Recovery status
aws dynamodb describe-table --table-name table-name

# Verify continuous backup compatibility
aws dynamodb describe-continuous-backups --table-name table-name
```

#### EFS Backup Issues
```bash
# Check EFS file system status
aws efs describe-file-systems --file-system-id fs-id

# Verify EFS backup policy
aws efs describe-backup-policy --file-system-id fs-id
```

## Cross-Region Backup Issues

### Cross-Region Not Supported Error

#### Problem
```
Error: InvalidParameterValueException: Cross region backups are not supported
```

#### Troubleshooting Steps

1. **Verify Source Region Support**
   ```bash
   aws backup describe-region-settings --region source-region
   ```

2. **Check Destination Region**
   ```bash
   aws backup describe-region-settings --region destination-region
   ```

3. **Verify Service Support**
   Not all AWS services support cross-region backups. Check the [AWS Backup documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html) for supported services.

### Cross-Region KMS Issues

#### Problem
```
Error: KMS key not accessible in destination region
```

#### Solutions

1. **Use Multi-Region KMS Keys**
   ```hcl
   resource "aws_kms_key" "backup" {
     description         = "Multi-region backup key"
     multi_region        = true
     deletion_window_in_days = 7
   }
   ```

2. **Configure Cross-Region Key Permissions**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "backup.amazonaws.com"
         },
         "Action": [
           "kms:Encrypt",
           "kms:Decrypt",
           "kms:ReEncrypt*",
           "kms:GenerateDataKey*",
           "kms:DescribeKey"
         ],
         "Resource": "*",
         "Condition": {
           "StringEquals": {
             "kms:ViaService": [
               "backup.us-east-1.amazonaws.com",
               "backup.us-west-2.amazonaws.com"
             ]
           }
         }
       }
     ]
   }
   ```

## Performance Issues

### Slow Backup Performance

#### EFS Backup Optimization
```hcl
# Increase backup windows for large EFS systems
rules = [
  {
    name              = "efs_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 240      # 4 hours
    completion_window = 2880     # 48 hours for very large EFS
    lifecycle = {
      delete_after = 30
    }
  }
]
```

#### RDS Backup Optimization
```hcl
# Stagger backup schedules to avoid conflicts
rules = [
  {
    name         = "rds_backup"
    schedule     = "cron(0 3 * * ? *)"  # After RDS automated backups
    start_window = 60
    lifecycle = {
      delete_after = 7
    }
  }
]
```

### Backup Window Timeout Issues

#### Problem
```
Error: BackupJobFailedException: Backup job failed to complete within the specified completion window
```

#### Solutions

1. **Increase Completion Window**
   ```hcl
   rules = [
     {
       name              = "large_resource_backup"
       schedule          = "cron(0 2 * * ? *)"
       start_window      = 120
       completion_window = 1440  # 24 hours
       lifecycle = {
         delete_after = 30
       }
     }
   ]
   ```

2. **Optimize Resource Configuration**
   - Use EFS Intelligent Tiering
   - Enable RDS storage optimization
   - Consider incremental backups where supported

## Monitoring & Logging

### CloudWatch Metrics

#### Key Metrics to Monitor
- `NumberOfBackupJobsCompleted`
- `NumberOfBackupJobsFailed`
- `NumberOfBackupJobsExpired`

#### CloudWatch Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "backup_failures" {
  alarm_name          = "backup-job-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup job failures"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }
}
```

### CloudTrail Logging

#### Enable CloudTrail for Backup Events
```hcl
resource "aws_cloudtrail" "backup_trail" {
  name           = "backup-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Backup::BackupVault"
      values = ["arn:aws:backup:*:*:backup-vault/*"]
    }
  }
}
```

## Common Error Messages

### InvalidParameterValueException

#### Message: "Invalid cron expression"
**Solution**: Verify cron expression format
```hcl
# Correct format: "cron(Minutes Hours Day-of-Month Month Day-of-Week Year)"
schedule = "cron(0 2 * * ? *)"  # Daily at 2 AM
```

#### Message: "Lifecycle delete_after must be greater than cold_storage_after"
**Solution**: Ensure proper lifecycle configuration
```hcl
lifecycle = {
  cold_storage_after = 30  # Move to cold storage after 30 days
  delete_after       = 90  # Delete after 90 days (must be > cold_storage_after)
}
```

### ResourceNotFoundException

#### Message: "Backup plan not found"
**Solution**: Check backup plan ID and region
```bash
aws backup list-backup-plans --region your-region
```

#### Message: "Backup vault not found"
**Solution**: Verify vault name and region
```bash
aws backup list-backup-vaults --region your-region
```

### ConflictException

#### Message: "Vault lock is already configured"
**Solution**: Check vault lock status
```bash
aws backup describe-backup-vault --backup-vault-name vault-name
```

If vault lock needs to be modified, create a new vault.

## Getting Additional Help

### AWS Support
- Open a support case for AWS Backup issues
- Include CloudTrail logs and backup job IDs
- Provide Terraform configuration (sanitized)

### Community Resources
- [AWS Backup User Guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Backup Forum](https://forums.aws.amazon.com/forum.jspa?forumID=345)

### Debug Information to Collect
When requesting help, provide:
1. Terraform version: `terraform version`
2. AWS provider version
3. Complete error messages
4. Relevant CloudTrail logs
5. Backup job IDs (if applicable)
6. Sanitized Terraform configuration

## Related Documentation
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) - Common known issues and solutions
- [BEST_PRACTICES.md](BEST_PRACTICES.md) - AWS Backup best practices
- [PERFORMANCE.md](PERFORMANCE.md) - Performance optimization guide
