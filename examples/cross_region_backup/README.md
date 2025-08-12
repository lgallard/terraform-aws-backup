# Cross-Region Backup Example

This example demonstrates how to implement cross-region backup replication using the terraform-aws-backup module for disaster recovery and compliance requirements.

## Use Case

Cross-region backup replication provides:
- **Disaster Recovery**: Protection against regional outages
- **Compliance**: Meeting regulatory requirements for geographic data distribution
- **Business Continuity**: Ensuring data availability across multiple regions

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

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   primary_region   = "us-east-1"
   secondary_region = "us-west-2"
   vault_name       = "my-cross-region-vault"
   environment      = "prod"
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Cost Optimization

**Estimated Monthly Costs** (for 100 GB):
- Primary region storage: ~$5/month (warm) + ~$1/month (cold)
- Secondary region storage: ~$5/month (warm) + ~$1/month (cold)
- Cross-region transfer: ~$2/month
- **Total**: ~$14/month for 100 GB with cross-region protection

## Example Use Cases

- **Enterprise DR**: Large organizations with strict RTO/RPO requirements
- **Regulated Industries**: Healthcare, financial services with compliance needs
- **Global Applications**: Multi-region applications requiring data locality
