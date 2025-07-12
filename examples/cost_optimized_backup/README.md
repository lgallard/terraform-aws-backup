# Cost-Optimized Backup Example

This example demonstrates cost optimization strategies for AWS Backup using a multi-tier backup approach that balances protection requirements with storage costs.

## Use Case

Cost-optimized backup strategies provide:
- **Tiered Protection**: Different backup frequencies and retention periods based on data criticality
- **Intelligent Storage Transitions**: Automatic movement to cold storage to reduce costs
- **Resource Prioritization**: Critical resources get more frequent backups, development resources get minimal backups
- **Cost Visibility**: Clear cost optimization through strategic lifecycle management

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Critical      │    │    Standard     │    │  Development    │
│   Resources     │    │   Resources     │    │   Resources     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Every 6 hours │    │ • Daily at 2 AM │    │ • Weekly (Sun)  │
│ • 1d → Cold     │    │ • 30d → Cold    │    │ • No Cold       │
│ • 30d Retention │    │ • 90d Retention │    │ • 7d Retention  │
│ • Production DB │    │ • EC2, EFS      │    │ • Dev DBs       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Cost Optimization Strategy

### Tier 1: Critical Resources
- **Frequency**: Every 6 hours for maximum protection
- **Storage**: Quick transition to cold storage (1 day) to minimize warm storage costs
- **Retention**: Short 30-day retention to balance protection with cost
- **Use Case**: Production databases, critical application data

### Tier 2: Standard Resources  
- **Frequency**: Daily backups during off-hours
- **Storage**: 30-day warm storage, then cold storage for cost savings
- **Retention**: 90-day retention for operational recovery needs
- **Use Case**: EC2 instances, EFS file systems, staging databases

### Tier 3: Development Resources
- **Frequency**: Weekly backups to minimize storage costs
- **Storage**: No cold storage transition (short retention makes it unnecessary)
- **Retention**: 7-day retention for quick recovery only
- **Use Case**: Development databases, test environments

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   region      = "us-east-1"
   vault_name  = "my-cost-optimized-vault"
   environment = "prod"
   
   critical_resources = [
     "arn:aws:rds:us-east-1:123456789012:db:production-app-db",
     "arn:aws:dynamodb:us-east-1:123456789012:table/production-user-data"
   ]
   
   standard_resources = [
     "arn:aws:ec2:us-east-1:123456789012:instance/*",
     "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/*"
   ]
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Cost Estimation

**Example monthly costs for 100 GB of data:**

| Tier | Frequency | Warm Storage | Cold Storage | Total/Month |
|------|-----------|--------------|--------------|-------------|
| Critical | 6-hourly | $1 (1 day) | $4 (29 days) | ~$5 |
| Standard | Daily | $5 (30 days) | $2 (60 days) | ~$7 |
| Development | Weekly | $1 (7 days) | $0 | ~$1 |
| **Total** | | | | **~$13/month** |

*Compared to $25/month for standard daily backups with warm storage*

## Benefits

- **60% cost reduction** compared to uniform backup strategies
- **Automated lifecycle management** reduces manual intervention
- **Scalable approach** that grows with your infrastructure
- **Compliance-ready** with appropriate retention periods
- **Resource tagging** enables easy cost allocation and monitoring

## Customization

### Adjusting Backup Frequencies
```hcl
# More frequent critical backups
schedule = "cron(0 */4 * * ? *)"  # Every 4 hours

# Less frequent development backups  
schedule = "cron(0 1 ? * MON *)"  # Weekly on Monday
```

### Modifying Lifecycle Policies
```hcl
lifecycle = {
  cold_storage_after = 7   # Keep in warm storage longer (minimum 1 day)
  delete_after       = 180 # Extended retention period
}

# To disable cold storage completely, omit cold_storage_after:
lifecycle = {
  delete_after = 30 # Only specify retention period
}
```

### Resource Selection by Tags
```hcl
selection_tags = [
  {
    type  = "STRINGEQUALS"
    key   = "CostTier"
    value = "Critical"
  },
  {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = "production"
  }
]
```

## Example Use Cases

- **Startups**: Minimize backup costs while maintaining essential protection
- **Cost-conscious enterprises**: Optimize backup spending across large infrastructures  
- **Multi-environment setups**: Different backup strategies for prod/staging/dev
- **Regulated industries**: Meet compliance requirements cost-effectively