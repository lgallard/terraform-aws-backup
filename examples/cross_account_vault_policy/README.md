# Cross-Account Backup Vault Policy Example

This example demonstrates how to configure an AWS Backup vault with access policies for cross-account backup scenarios. This is essential for enterprise disaster recovery strategies where backups are copied to a centralized DR account.

## Features Demonstrated

- **Backup Vault Policy**: IAM policy for cross-account backup access
- **Cross-Account Permissions**: Secure access control for source accounts
- **KMS Encryption**: Customer-managed KMS key for vault encryption
- **Vault Lock**: Compliance-grade immutable backup retention
- **Audit Access**: Special permissions for compliance and audit roles

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Source Acct 1  │    │  Source Acct 2  │    │   Audit Acct    │
│  (Production)   │    │  (Staging)      │    │  (Compliance)   │
│                 │    │                 │    │                 │
│  ┌─────────────┐│    │  ┌─────────────┐│    │  ┌─────────────┐│
│  │Backup Plans ││    │  │Backup Plans ││    │  │ Audit Role  ││
│  │             ││    │  │             ││    │  │             ││
│  │Copy Actions ││    │  │Copy Actions ││    │  │Read Access  ││
│  └─────────────┘│    │  └─────────────┘│    │  └─────────────┘│
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │     Copy Backups     │         Audit        │
          └──────────┐  ┌────────┘         Access       │
                     │  │                               │
                     ▼  ▼                               ▼
              ┌─────────────────────────────────────────────┐
              │           Destination Account               │
              │              (DR Account)                  │
              │                                            │
              │  ┌─────────────────────────────────────┐   │
              │  │         DR Backup Vault             │   │
              │  │                                     │   │
              │  │  • Vault Access Policy              │   │
              │  │  • KMS Encryption                   │   │
              │  │  • Vault Lock (Compliance)          │   │
              │  │  • Cross-Region Replication Ready   │   │
              │  └─────────────────────────────────────┘   │
              └─────────────────────────────────────────────┘
```

## Use Cases

### 1. Enterprise Disaster Recovery
- Central DR account receives backups from all production accounts
- Immutable backup storage with vault lock for compliance
- Encrypted storage with customer-managed KMS keys

### 2. Compliance and Audit Requirements
- SOX, HIPAA, PCI DSS compliance through immutable backups
- Audit trails for all cross-account backup operations
- Separate audit account access for independent verification

### 3. Multi-Account AWS Organizations
- Member accounts backup to organization's backup account
- Centralized backup governance and cost management
- Simplified backup monitoring and alerting

### 4. Hybrid and Multi-Cloud Strategies
- AWS-to-AWS backup copy for additional resilience
- Integration with on-premises backup strategies
- Cross-region disaster recovery scenarios

## Configuration

### Basic Configuration

```hcl
module "cross_account_backup" {
  source = "lgallard/backup/aws//examples/cross_account_vault_policy"

  # Source accounts allowed to copy backups
  source_account_ids = [
    "123456789012",  # Production account
    "987654321098"   # Staging account
  ]

  # Regions from which backups can be copied
  allowed_source_regions = ["us-east-1", "us-west-2"]

  # Compliance settings
  enable_vault_lock      = true
  min_retention_days     = 30
  max_retention_days     = 2555  # 7 years
  lock_changeable_for_days = 7   # Compliance mode after 7 days

  # Audit access
  audit_role_arn = "arn:aws:iam::999999999999:role/BackupAuditRole"

  tags = {
    Purpose     = "DisasterRecovery"
    Compliance  = "SOX"
    Environment = "production"
  }
}
```

### Advanced Configuration

For more complex scenarios, you can customize the vault policy:

```hcl
# Custom vault policy with additional conditions
data "aws_iam_policy_document" "custom_vault_policy" {
  statement {
    sid    = "AllowCrossAccountBackupCopy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        for account_id in var.source_account_ids :
        "arn:aws:iam::${account_id}:role/AWSBackupServiceRole"
      ]
    }

    actions = ["backup:CopyIntoBackupVault"]
    resources = ["*"]

    # Additional security conditions
    condition {
      test     = "StringEquals"
      variable = "backup:CopySourceRegion"
      values   = var.allowed_source_regions
    }

    condition {
      test     = "DateGreaterThan"
      variable = "aws:CurrentTime"
      values   = ["2024-01-01T00:00:00Z"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["10.0.0.0/8", "172.16.0.0/12"]  # Corporate IP ranges
    }
  }
}

module "advanced_cross_account_backup" {
  source = "lgallard/backup/aws"

  vault_name   = "secure-dr-vault"
  vault_policy = data.aws_iam_policy_document.custom_vault_policy.json

  # Additional security configuration
  vault_policy_bypass_security_validation = false  # Strict security validation

  # ... other configuration
}
```

## Source Account Setup

### 1. IAM Policy for Source Accounts

Create this IAM policy in each source account:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowBackupCopyToDestination",
      "Effect": "Allow",
      "Action": [
        "backup:CopyIntoBackupVault",
        "backup:DescribeBackupVault"
      ],
      "Resource": [
        "arn:aws:backup:*:DESTINATION_ACCOUNT_ID:backup-vault:*"
      ]
    },
    {
      "Sid": "AllowKMSAccess",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:CreateGrant"
      ],
      "Resource": "arn:aws:kms:*:DESTINATION_ACCOUNT_ID:key/*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "backup.REGION.amazonaws.com"
        }
      }
    }
  ]
}
```

### 2. Backup Plan with Copy Actions

```hcl
resource "aws_backup_plan" "source_plan" {
  name = "production-backup-plan"

  rule {
    rule_name         = "daily_backup_with_copy"
    target_vault_name = "source-vault"
    schedule          = "cron(0 5 ? * * *)"  # 5 AM daily

    lifecycle {
      cold_storage_after = 30
      delete_after      = 120
    }

    # Copy to DR account
    copy_action {
      destination_vault_arn = "arn:aws:backup:us-east-1:DR_ACCOUNT_ID:backup-vault:dr-vault-xxx"

      lifecycle {
        cold_storage_after = 30
        delete_after      = 2555  # 7 years in DR account
      }
    }
  }
}
```

## Security Considerations

### 1. KMS Key Management
- Uses customer-managed KMS keys for encryption
- Cross-account access properly configured
- Key rotation enabled by default

### 2. Least Privilege Access
- Vault policy grants minimum required permissions
- Source account access restricted to specific accounts and regions
- Audit access is read-only

### 3. Compliance Features
- Vault lock prevents premature deletion
- Immutable backups for regulatory compliance
- Audit trail for all operations

### 4. Network Security
- Optional IP address restrictions
- VPC endpoint support for private communication
- CloudTrail logging for all API calls

## Monitoring and Alerting

### CloudWatch Metrics
- `AWS/Backup NumberOfBackupJobsCompleted`
- `AWS/Backup NumberOfBackupJobsFailed`
- `AWS/Backup NumberOfRecoveryPointsCreated`

### CloudTrail Events
- `CopyIntoBackupVault` - Cross-account copy operations
- `PutBackupVaultAccessPolicy` - Policy changes
- `DeleteBackupVaultAccessPolicy` - Policy removals

### SNS Notifications
```hcl
# Add to your backup configuration
notifications = {
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "COPY_JOB_STARTED",
    "COPY_JOB_SUCCESSFUL",
    "COPY_JOB_FAILED"
  ]
  sns_topic_arn = aws_sns_topic.backup_notifications.arn
}
```

## Cost Optimization

### 1. Lifecycle Management
- Move to cold storage after 30 days (75% cost reduction)
- Archive tier for long-term retention (90% cost reduction)
- Appropriate deletion schedules

### 2. Cross-Region Considerations
- Copy only critical backups cross-region
- Use lifecycle policies to minimize storage costs
- Monitor cross-region data transfer charges

### 3. Backup Frequency
- Daily backups for production workloads
- Weekly backups for development environments
- Point-in-time recovery for databases

## Testing and Validation

### 1. Backup Copy Testing
```bash
# Test backup copy from source account
aws backup start-backup-job \
  --backup-vault-name source-vault \
  --resource-arn arn:aws:dynamodb:us-east-1:123456789012:table/test-table \
  --iam-role-arn arn:aws:iam::123456789012:role/AWSBackupServiceRole

# Verify in destination account
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name dr-vault-xxx
```

### 2. Restore Testing
```bash
# Test restore from DR account
aws backup start-restore-job \
  --recovery-point-arn arn:aws:backup:us-east-1:DR_ACCOUNT:recovery-point:xxx \
  --metadata '{"TableName":"test-table-restored"}' \
  --iam-role-arn arn:aws:iam::DR_ACCOUNT:role/AWSBackupServiceRole
```

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Verify source account IAM policies
   - Check KMS key permissions
   - Confirm vault policy allows source account

2. **Copy Job Failures**
   - Check network connectivity
   - Verify region restrictions in vault policy
   - Review CloudTrail logs for detailed errors

3. **Encryption Issues**
   - Ensure KMS key policy allows cross-account access
   - Verify `kms:ViaService` condition is correct
   - Check key permissions for backup service

## Integration with Other Services

### AWS Organizations
```hcl
# Organization-wide backup policy
resource "aws_organizations_policy" "backup_policy" {
  name        = "CrossAccountBackupPolicy"
  description = "Backup policy for all organization accounts"
  type        = "BACKUP_POLICY"

  content = jsonencode({
    plans = {
      OrgBackupPlan = {
        regions = ["us-east-1", "us-west-2"]

        copy_actions = {
          arn:aws:backup:us-east-1:DR_ACCOUNT_ID:backup-vault:dr-vault = {
            target_backup_vault_arn = "arn:aws:backup:us-east-1:DR_ACCOUNT_ID:backup-vault:dr-vault"
            lifecycle = {
              delete_after_days = 2555
            }
          }
        }
      }
    }
  })
}
```

### AWS Config
```hcl
# Monitor vault policy changes
resource "aws_config_config_rule" "backup_vault_policy_check" {
  name = "backup-vault-policy-check"

  source {
    owner             = "AWS"
    source_identifier = "BACKUP_VAULT_ACCESS_POLICY_CONFIGURED"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}
```

## Related Examples

- [Simple Plan](../simple_plan/) - Basic backup configuration
- [Secure Backup Configuration](../secure_backup_configuration/) - Additional security features
- [Organization Backup Policy](../organization_backup_policy/) - Enterprise governance

## Additional Resources

- [AWS Backup Cross-Account Documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/create-cross-account-backup.html)
- [Vault Access Policy Guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/create-a-vault-access-policy.html)
- [AWS Backup Security Best Practices](https://docs.aws.amazon.com/aws-backup/latest/devguide/security-best-practices.html)
