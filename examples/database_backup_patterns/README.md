# Database-Specific Backup Patterns

This example demonstrates optimized backup strategies for different database types and workload tiers. It provides production-ready patterns for RDS, DynamoDB, DocumentDB, and Aurora clusters with appropriate backup frequencies, retention policies, and cost optimization.

## Use Cases

- **Critical Production Databases**: High-frequency backups with point-in-time recovery
- **Standard Application Databases**: Daily backups with balanced cost and protection
- **Development Databases**: Cost-effective weekly backups for testing environments
- **Analytics Databases**: Long-term retention for compliance and data analysis

## Architecture Overview

```
Database Backup Tiers
┌─────────────────────────────────────────────────────────────────┐
│ Critical Tier (Every 6h, 90d retention, Continuous backup)     │
│ ├─ Production RDS instances (prod-*)                            │
│ ├─ Production Aurora clusters (prod-aurora-*)                   │
│ └─ Mission-critical databases                                   │
├─────────────────────────────────────────────────────────────────┤
│ Standard Tier (Daily, 180d retention)                          │
│ ├─ Application databases (app-*)                                │
│ ├─ Staging environments                                         │
│ └─ DynamoDB tables (user-*, session-*, analytics-*)            │
├─────────────────────────────────────────────────────────────────┤
│ Development Tier (Weekly, 30d retention)                       │
│ ├─ Development databases (dev-*)                                │
│ └─ Testing environments                                         │
├─────────────────────────────────────────────────────────────────┤
│ DynamoDB Strategy (Daily, 365d retention, Long cold storage)   │
│ ├─ Analytics tables                                             │
│ ├─ Historical data                                              │
│ └─ Compliance data                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Tier Backup Strategy**: Different backup frequencies and retention for different database tiers
- **Database-Optimized Settings**: Tailored backup windows and settings for each database type
- **Cost Optimization**: Intelligent cold storage transitions and retention policies
- **Point-in-Time Recovery**: Continuous backup for critical databases
- **Automated Monitoring**: CloudWatch alarms and optional Lambda-based validation
- **Compliance Ready**: Long-term retention options for regulatory requirements

## Database Types Supported

### Amazon RDS
- **MySQL, PostgreSQL, MariaDB**: Standard relational database backups
- **Oracle, SQL Server**: Enterprise database backup patterns
- **Multi-AZ and Read Replicas**: Optimized backup strategies

### Amazon Aurora
- **Aurora MySQL/PostgreSQL**: Cluster-aware backup configurations
- **Aurora Serverless**: Optimized for serverless workloads
- **Global Database**: Cross-region cluster backup support

### Amazon DynamoDB
- **Tables and Global Tables**: Optimized for NoSQL workloads
- **Point-in-Time Recovery**: Continuous backup options
- **Analytics Integration**: Long-term retention for data analysis

### Amazon DocumentDB
- **MongoDB-compatible**: Document database backup patterns
- **Cluster backups**: Optimized for document workloads

## Quick Start

1. **Configure your database resources:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   vault_name = "my-database-backup-vault"
   environment = "prod"
   
   critical_rds_resources = [
     "arn:aws:rds:us-east-1:123456789012:db:prod-primary-db",
     "arn:aws:rds:us-east-1:123456789012:cluster:prod-aurora-cluster"
   ]
   
   standard_rds_resources = [
     "arn:aws:rds:us-east-1:123456789012:db:app-backend-db"
   ]
   
   dynamodb_resources = [
     "arn:aws:dynamodb:us-east-1:123456789012:table/user-sessions",
     "arn:aws:dynamodb:us-east-1:123456789012:table/analytics-events"
   ]
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Backup Strategies

### Critical Database Strategy
- **Frequency**: Every 6 hours
- **Continuous Backup**: Enabled (point-in-time recovery)
- **Retention**: 90 days
- **Cold Storage**: After 7 days
- **Use Cases**: Production databases, financial systems, user data

### Standard Database Strategy
- **Frequency**: Daily at 3 AM
- **Continuous Backup**: Disabled
- **Retention**: 180 days (6 months)
- **Cold Storage**: After 30 days
- **Use Cases**: Application databases, staging environments

### Development Database Strategy
- **Frequency**: Weekly (Sunday at 1 AM)
- **Continuous Backup**: Disabled
- **Retention**: 30 days
- **Cold Storage**: Disabled
- **Use Cases**: Development, testing, temporary databases

### DynamoDB Strategy
- **Frequency**: Daily at 4 AM
- **Continuous Backup**: Optional
- **Retention**: 365 days (1 year)
- **Cold Storage**: After 90 days
- **Use Cases**: Analytics data, user profiles, session data

## Cost Optimization

### Estimated Monthly Costs (per 100 GB)

| Database Tier | Backup Storage | Cold Storage | Total/Month |
|---------------|---------------|--------------|-------------|
| Critical      | $15 (frequent) | $3 (7d transition) | ~$18 |
| Standard      | $8 (daily) | $2 (30d transition) | ~$10 |
| Development   | $3 (weekly) | $0 (no cold storage) | ~$3 |
| DynamoDB      | $5 (daily) | $1 (90d transition) | ~$6 |

### Cost Optimization Features
- **Intelligent Tiering**: Automatic cold storage transitions
- **Retention Policies**: Appropriate retention periods by tier
- **Backup Windows**: Optimized to avoid peak usage periods
- **Resource Selection**: Tag-based and ARN-based filtering

## Monitoring and Alerting

### CloudWatch Metrics
Monitor these key metrics:
- `NumberOfBackupJobsCompleted`
- `NumberOfBackupJobsFailed`
- `NumberOfRecoveryPointsCreated`

### Automated Alerts
- **Backup Failures**: Immediate SNS notifications
- **Missing Backups**: Daily validation checks
- **Storage Costs**: Monthly cost analysis

### Optional Lambda Validation
Enable automated backup validation:
```hcl
enable_backup_validation = true
alarm_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:backup-alerts"
```

## Advanced Configuration

### Custom Backup Windows
```hcl
backup_windows = {
  critical = {
    start_window      = 60   # 1 hour start window
    completion_window = 240  # 4 hours completion window
  }
  standard = {
    start_window      = 120  # 2 hours start window
    completion_window = 360  # 6 hours completion window
  }
}
```

### Environment-Specific Settings
```hcl
# Production
environment = "prod"
critical_retention_days = 90
enable_monitoring = true

# Staging
environment = "staging"
critical_retention_days = 30
enable_monitoring = false

# Development
environment = "dev"
critical_retention_days = 7
enable_monitoring = false
```

### Database-Specific Optimizations

#### RDS Optimization
- **Large Databases**: Extended completion windows
- **Multi-AZ**: Backup from secondary for performance
- **Read Replicas**: Backup from replica to reduce primary load

#### DynamoDB Optimization
- **Point-in-Time Recovery**: Enable for critical tables
- **Global Tables**: Backup coordination across regions
- **Large Tables**: Parallel backup jobs

#### Aurora Optimization
- **Cluster Backups**: Backup entire cluster atomically
- **Serverless**: Optimized for auto-scaling workloads
- **Global Database**: Cross-region backup strategies

## Security Best Practices

### Encryption
- **Vault Encryption**: Customer-managed KMS keys
- **Backup Encryption**: Automatic encryption at rest
- **In-Transit**: Encrypted backup transfers

### Access Control
- **IAM Roles**: Least privilege access
- **Resource Tags**: Fine-grained access control
- **Vault Policies**: Backup vault access restrictions

### Compliance
- **Data Residency**: Region-specific backup storage
- **Retention Policies**: Meet regulatory requirements
- **Audit Trails**: CloudTrail integration

## Performance Tuning

### Backup Windows
- **Off-Peak Hours**: Schedule during low usage periods
- **Staggered Backups**: Distribute load across time windows
- **Resource Allocation**: Adequate completion windows

### Network Optimization
- **VPC Endpoints**: Use backup VPC endpoints
- **Bandwidth**: Consider backup data transfer volumes
- **Regional**: Backup in same region as resources

## Testing and Validation

### Backup Testing
```bash
# List recent backup jobs
aws backup list-backup-jobs --by-backup-vault-name database-backup-vault

# Test restore capabilities
aws backup start-restore-job \
  --recovery-point-arn arn:aws:backup:us-east-1:123456789012:recovery-point:12345678-1234-1234-1234-123456789012 \
  --metadata InstanceType=db.t3.micro
```

### Validation Scripts
The example includes optional Lambda-based validation:
- Daily backup job verification
- Failed backup notifications
- Cost monitoring alerts

## Troubleshooting

### Common Issues

1. **Backup Failures**
   - Check IAM permissions
   - Verify resource accessibility
   - Review backup windows

2. **Performance Issues**
   - Adjust completion windows
   - Optimize backup schedules
   - Monitor resource utilization

3. **Cost Overruns**
   - Review retention policies
   - Optimize cold storage transitions
   - Audit backup frequency

### Monitoring Commands
```bash
# Check backup job status
aws backup describe-backup-job --backup-job-id <job-id>

# List failed jobs
aws backup list-backup-jobs --by-state FAILED

# Monitor costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE
```

## Migration Guide

### From Manual Backups
1. Inventory existing backup procedures
2. Map databases to appropriate tiers
3. Configure backup plans
4. Test restore procedures
5. Disable manual backups

### From Other Backup Solutions
1. Assess current backup frequencies
2. Map retention requirements
3. Plan migration windows
4. Validate backup integrity
5. Switch over gradually

## Best Practices

1. **Start with Standard Tier**: Begin with daily backups for most databases
2. **Monitor Costs**: Track backup storage costs monthly
3. **Test Restores**: Regular restore testing (monthly recommended)
4. **Tag Resources**: Consistent tagging for automated selection
5. **Review Regularly**: Quarterly review of backup strategies
6. **Document Procedures**: Maintain backup and restore runbooks