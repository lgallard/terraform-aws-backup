# Known Issues

## Error Creating Backup Vault

### Problem
In case you get an error message similar to this one:

```
error creating Backup Vault (): AccessDeniedException: status code: 403, request id: 8e7e577e-5b74-4d4d-95d0-bf63e0b2cc2e
```

### Root Cause
This error typically occurs when:
- AWS Backup service is not available in the target region
- Insufficient IAM permissions for the AWS Backup service
- AWS Backup service-linked role has not been created
- The region doesn't support AWS Backup (check [AWS Regional Services](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/))

### Solutions

#### 1. Enable AWS Backup Service
Go to the AWS Console → AWS Backup in your target region and ensure the service is enabled.

#### 2. Check IAM Permissions
Ensure your IAM user/role has the necessary permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "backup:CreateBackupVault",
        "backup:PutBackupVaultAccessPolicy",
        "backup:DescribeBackupVault"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 3. Create Service-Linked Role
Create the AWS Backup service-linked role if it doesn't exist:

```bash
aws iam create-service-linked-role --aws-service-name backup.amazonaws.com
```

Or using Terraform:
```hcl
resource "aws_iam_service_linked_role" "backup" {
  aws_service_name = "backup.amazonaws.com"
}
```

## Cross-Region Backup Issues

### Problem
```
error creating Backup Selection: InvalidParameterValueException: Cross region backups are not supported
```

### Root Cause
- The destination region doesn't support cross-region backups
- Cross-region backup configuration is incorrect
- KMS key permissions for cross-region operations are missing

### Solutions

#### 1. Verify Region Support
Check that both source and destination regions support cross-region backups in the [AWS documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/cross-region-backup.html).

#### 2. Configure KMS Key Permissions
Ensure the KMS key used for encryption allows cross-region operations:

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

## Vault Lock Configuration Issues

### Problem
```
error creating Backup Vault Lock: InvalidParameterValueException: Vault lock configuration is immutable
```

### Root Cause
- Attempting to modify an already locked vault
- Incorrect vault lock configuration parameters
- Trying to enable vault lock on a vault with existing backups

### Solutions

#### 1. Check Vault Lock Status
Before attempting to configure vault lock, verify the current status:

```bash
aws backup describe-backup-vault --backup-vault-name your-vault-name
```

#### 2. Create New Vault for Lock Configuration
If you need to change vault lock settings, create a new vault:

```hcl
resource "aws_backup_vault" "locked_vault" {
  name        = "locked-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn
  
  # Vault lock configuration
  force_destroy = false
}
```

## DynamoDB Backup Issues

### Problem
```
error creating Backup Plan: InvalidParameterValueException: Continuous backups are not supported for DynamoDB
```

### Root Cause
- DynamoDB continuous backups require Point-in-Time Recovery (PITR) to be enabled
- The DynamoDB table doesn't support the requested backup frequency

### Solutions

#### 1. Enable PITR for DynamoDB
```hcl
resource "aws_dynamodb_table" "example" {
  name           = "example"
  hash_key       = "id"
  billing_mode   = "PAY_PER_REQUEST"
  
  # Enable Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }
  
  attribute {
    name = "id"
    type = "S"
  }
}
```

#### 2. Use Snapshot-Based Backups
For DynamoDB tables without PITR, use snapshot-based backups:

```hcl
rules = [
  {
    name                     = "daily_backup"
    schedule                 = "cron(0 2 * * ? *)"
    enable_continuous_backup = false  # Use snapshot backups
    lifecycle = {
      delete_after = 30
    }
  }
]
```

## EFS Backup Performance Issues

### Problem
EFS backups taking longer than expected or timing out.

### Root Cause
- Large EFS file systems require longer backup windows
- Network throughput limitations
- Concurrent backup operations

### Solutions

#### 1. Adjust Backup Windows
```hcl
rules = [
  {
    name              = "efs_backup"
    schedule          = "cron(0 2 * * ? *)"
    start_window      = 120      # 2 hours
    completion_window = 1440     # 24 hours for large EFS
    lifecycle = {
      delete_after = 30
    }
  }
]
```

#### 2. Optimize EFS Performance
- Use Provisioned Throughput mode for consistent performance
- Consider EFS Intelligent Tiering to reduce backup size

## RDS Backup Conflicts

### Problem
```
error: ConflictException: Cannot create backup while another backup is in progress
```

### Root Cause
- Automated RDS backups conflict with AWS Backup schedules
- Multiple backup plans targeting the same RDS instance

### Solutions

#### 1. Coordinate Backup Schedules
Ensure AWS Backup schedules don't conflict with RDS automated backups:

```hcl
# Schedule AWS Backup when RDS automated backups are not running
rules = [
  {
    name         = "rds_backup"
    schedule     = "cron(0 4 * * ? *)"  # 4 AM when RDS backups typically complete
    start_window = 60
    lifecycle = {
      delete_after = 7
    }
  }
]
```

#### 2. Disable RDS Automated Backups
If using AWS Backup exclusively:

```hcl
resource "aws_db_instance" "example" {
  # ... other configuration
  backup_retention_period = 0  # Disable automated backups
  backup_window          = null
}
```

## Troubleshooting Tips

### Enable Debug Logging
Set environment variables for detailed logging:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
```

### Check AWS Service Health
Before troubleshooting, check AWS Service Health Dashboard for any ongoing issues in your region.

### Verify Resource Tags
Ensure resources have proper tags for backup selection:
```hcl
tags = {
  "backup" = "true"
  "environment" = "production"
}
```

### Monitor Backup Jobs
Use AWS CloudWatch to monitor backup job status and set up alerts for failures.

For additional troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
