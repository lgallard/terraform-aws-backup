# Cross-Region Backup Example

This example demonstrates how to implement cross-region backup replication using the terraform-aws-backup module. This pattern is essential for disaster recovery, compliance requirements, and business continuity planning.

## Use Case

Cross-region backup replication provides:
- **Disaster Recovery**: Protection against regional outages or disasters
- **Compliance**: Meeting regulatory requirements for geographic data distribution
- **Business Continuity**: Ensuring data availability across multiple regions
- **Risk Mitigation**: Reducing single points of failure

## Architecture

```
Primary Region (us-east-1)        Secondary Region (us-west-2)
┌─────────────────────────┐       ┌─────────────────────────┐
│ Primary Backup Vault    │       │ Secondary Backup Vault  │
│ ├─ Daily Backups        │────── │ ├─ Replicated Backups   │
│ ├─ 30d → Cold Storage   │ Copy  │ ├─ 30d → Cold Storage   │
│ └─ 365d Retention       │ Job   │ └─ 365d Retention       │
└─────────────────────────┘       └─────────────────────────┘
```

## Features

- **Automated Cross-Region Replication**: Daily backups automatically replicated to secondary region
- **Lifecycle Management**: Cost-optimized storage transitions (30 days to cold storage)
- **Comprehensive Monitoring**: SNS notifications for backup and copy job events
- **Resource Selection**: Tag-based and ARN-based resource selection
- **Compliance Ready**: 365-day retention for regulatory requirements

## Prerequisites

1. **AWS Credentials**: Configured with appropriate permissions in both regions
2. **KMS Keys**: Customer-managed KMS keys in both regions (recommended)
3. **SNS Topic**: For backup event notifications (optional)
4. **S3 Bucket**: For backup reports (optional)

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your specific values:**
   ```hcl
   primary_region   = "us-east-1"
   secondary_region = "us-west-2"
   vault_name       = "my-cross-region-vault"
   environment      = "prod"
   
   backup_resources = [
     "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0",
     "arn:aws:rds:us-east-1:123456789012:db:my-database"
   ]
   ```

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Options

### Resource Selection Methods

**ARN-based Selection:**
```hcl
backup_resources = [
  "arn:aws:ec2:*:*:instance/*",           # All EC2 instances
  "arn:aws:rds:*:*:db:prod-*",            # RDS instances with prod- prefix
  "arn:aws:dynamodb:*:*:table/important-*" # DynamoDB tables with important- prefix
]
```

**Tag-based Selection:**
Resources are automatically selected based on these tags:
- `BackupRequired = "true"`
- `Environment = var.environment`

### Backup Schedule

- **Frequency**: Daily at 2:00 AM (configurable via cron expression)
- **Windows**: 1-hour start window, 8-hour completion window
- **Lifecycle**: 30 days → cold storage, 365 days total retention

### Cost Optimization

**Estimated Monthly Costs** (for 100 GB of data):
- Primary region storage: ~$5/month (warm) + ~$1/month (cold after 30 days)
- Secondary region storage: ~$5/month (warm) + ~$1/month (cold after 30 days)
- Cross-region transfer: ~$2/month (one-time per backup)
- **Total**: ~$14/month for 100 GB with cross-region protection

## Monitoring and Alerts

### SNS Notifications

The example configures notifications for:
- Backup job started/completed/failed
- Copy job started/successful/failed

### CloudWatch Metrics

Monitor these key metrics:
- `NumberOfBackupJobsCompleted`
- `NumberOfCopyJobsCompleted`
- `NumberOfBackupJobsFailed`

### Backup Reports

Optional backup reports provide:
- Backup job status across both regions
- Compliance reporting
- Cost analysis
- Failure notifications

## Security Best Practices

1. **KMS Encryption**: Use customer-managed KMS keys in both regions
2. **Least Privilege**: IAM roles follow principle of least privilege
3. **Vault Locking**: Consider enabling vault lock for compliance workloads
4. **Network Security**: Ensure cross-region traffic follows security guidelines

## Testing and Validation

### Backup Validation
```bash
# List backup jobs
aws backup list-backup-jobs --by-backup-vault-name cross-region-backup-vault

# List copy jobs
aws backup list-copy-jobs --by-destination-vault-arn arn:aws:backup:us-west-2:ACCOUNT:backup-vault:cross-region-backup-vault-secondary
```

### Restore Testing
```bash
# Test restore from primary region
aws backup start-restore-job --recovery-point-arn <primary-recovery-point-arn> --metadata InstanceType=t3.micro

# Test restore from secondary region
aws backup start-restore-job --region us-west-2 --recovery-point-arn <secondary-recovery-point-arn> --metadata InstanceType=t3.micro
```

## Cleanup

To avoid ongoing costs when testing:

```bash
terraform destroy
```

**Warning**: This will delete all backup vaults and recovery points. Ensure you have alternative backups before destroying.

## Advanced Configuration

### Multiple Backup Policies

For different RPO/RTO requirements:

```hcl
rules = [
  {
    name     = "critical-hourly"
    schedule = "cron(0 */4 * * ? *)"  # Every 4 hours for critical data
    # ... lifecycle configuration
  },
  {
    name     = "standard-daily"
    schedule = "cron(0 2 * * ? *)"    # Daily for standard data
    # ... lifecycle configuration
  }
]
```

### Compliance Configuration

For regulatory compliance:

```hcl
# Enable vault locking
locked             = true
min_retention_days = 90   # Minimum 90 days for compliance
max_retention_days = 2555 # Maximum 7 years
changeable_for_days = 3   # Grace period before lock becomes immutable
```

## Troubleshooting

### Common Issues

1. **Cross-region permissions**: Ensure IAM roles have permissions in both regions
2. **KMS key access**: Verify KMS keys are accessible from backup service
3. **Network connectivity**: Check VPC endpoints and routing for cross-region traffic
4. **Resource limits**: Monitor AWS Backup service limits in both regions

### Support Resources

- [AWS Backup User Guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/)
- [Cross-Region Backup Documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/cross-region-backup.html)
- [AWS Backup Pricing](https://aws.amazon.com/backup/pricing/)

## Example Use Cases

- **Enterprise DR**: Large organizations with strict RTO/RPO requirements
- **Regulated Industries**: Healthcare, financial services with compliance needs
- **Global Applications**: Multi-region applications requiring data locality
- **Critical Workloads**: Mission-critical systems requiring maximum availability