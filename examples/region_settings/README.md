# Region Settings Example

This example demonstrates how to configure AWS Backup region settings to control which AWS services are enabled for backup operations at the region level.

## Overview

AWS Backup region settings allow you to:
- **Enable/disable specific AWS services** for backup operations in a region
- **Configure resource type management preferences** for advanced backup features
- **Control service-level backup capabilities** without modifying individual backup plans

## Use Case

Region settings are particularly useful when:
- **Implementing security policies** that restrict which services can be backed up
- **Managing multi-region deployments** with different service requirements per region
- **Optimizing costs** by disabling backup for unused services
- **Compliance requirements** dictate specific service enablement patterns
- **Gradual rollout** of backup capabilities across your AWS infrastructure

## Architecture

```
┌─────────────────────────────────────────────────────┐
│          AWS Backup Region Settings                 │
│                                                     │
│  Enabled Services (Opt-In):                        │
│  ✅ Aurora         ✅ DynamoDB      ✅ EBS         │
│  ✅ EC2            ✅ EFS           ✅ RDS         │
│  ✅ S3                                              │
│                                                     │
│  Disabled Services:                                │
│  ❌ FSx            ❌ Neptune       ❌ DocumentDB   │
│  ❌ Storage Gateway ❌ CloudFormation              │
│                                                     │
│  Management Enabled:                               │
│  🔧 DynamoDB (Advanced Features)                   │
│  🔧 EFS (Advanced Features)                        │
└─────────────────────────────────────────────────────┘
```

## Features Demonstrated

### 1. Service Opt-In Configuration
Controls which AWS services are discoverable and protectable by AWS Backup in this region.

### 2. Resource Type Management
Enables advanced management features for specific services (optional configuration).

### 3. Regional Isolation
Settings apply only to the current AWS region, allowing different configurations per region.

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars:**
   ```hcl
   region = "us-east-1"
   tags = {
     Environment = "production"
     Team        = "platform"
   }
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Configuration Details

### Enabled Services

The following services are enabled for backup operations:

| Service | Purpose | Common Use Cases |
|---------|---------|------------------|
| **Aurora** | Aurora database clusters | Production databases, OLTP workloads |
| **DynamoDB** | NoSQL tables | Application data, session storage |
| **EBS** | Elastic Block Store volumes | EC2 instance storage, application data |
| **EC2** | EC2 instances | Application servers, virtual machines |
| **EFS** | Elastic File System | Shared file storage, container storage |
| **RDS** | Relational databases | MySQL, PostgreSQL, SQL Server databases |
| **S3** | S3 buckets | Object storage, data lakes |

### Disabled Services

These services are disabled to demonstrate selective enablement:

| Service | Reason for Disabling (Example) |
|---------|-------------------------------|
| **FSx** | Not using FSx file systems in this region |
| **Neptune** | Graph database not deployed |
| **DocumentDB** | MongoDB workloads not present |
| **Storage Gateway** | Hybrid storage not configured |
| **CloudFormation** | Stack backup not required |
| **SAP HANA** | SAP workloads in different region |
| **VirtualMachine** | VMware integration not enabled |
| **DSQL** | DSQL not in use |
| **Redshift** | Data warehouse in different region |

### Management Preferences

Advanced management features are enabled for:
- **DynamoDB**: Enhanced backup management capabilities
- **EFS**: Advanced file system backup features

## Multi-Region Setup

To configure different settings per region, use provider aliases:

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# US East 1 - Production services
module "region_settings_us_east" {
  source = "lgallard/backup/aws"

  providers = {
    aws = aws.us_east_1
  }

  enable_region_settings = true
  region_settings = {
    resource_type_opt_in_preference = {
      "Aurora"   = true
      "DynamoDB" = true
      "RDS"      = true
      "S3"       = true
    }
  }
}

# EU West 1 - Different configuration
module "region_settings_eu_west" {
  source = "lgallard/backup/aws"

  providers = {
    aws = aws.eu_west_1
  }

  enable_region_settings = true
  region_settings = {
    resource_type_opt_in_preference = {
      "EBS"    = true
      "EC2"    = true
      "EFS"    = true
      "Redshift" = true  # Data warehouse in EU region
    }
  }
}
```

## Important Notes

### Service Enablement
- **Opt-in is required**: Services must be explicitly enabled before AWS Backup can protect them
- **Region-scoped**: Settings apply only to the current AWS region
- **No impact on existing backups**: Disabling a service doesn't delete existing recovery points

### Management vs. Opt-In
- **`resource_type_opt_in_preference`**: Controls whether a service can be backed up
- **`resource_type_management_preference`**: Enables advanced management features (optional)

### Validation
The module includes validation to ensure:
- Only valid AWS service names are specified
- At least one service is configured when region settings are enabled
- Service names match AWS Backup's expected format

## Outputs

After deployment, you'll receive:

```bash
terraform output
```

Example output:
```
enabled_services = [
  "Aurora",
  "DynamoDB",
  "EBS",
  "EC2",
  "EFS",
  "RDS",
  "S3",
]

service_count = {
  "disabled" = 9
  "enabled" = 7
  "managed" = 2
  "total_configured" = 16
}
```

## Verification

### Via AWS CLI

```bash
# Describe current region settings
aws backup describe-region-settings

# List supported resource types
aws backup get-supported-resource-types

# Verify protected resources
aws backup list-protected-resources
```

### Via AWS Console

1. Navigate to **AWS Backup Console**
2. Go to **Settings** → **Region settings**
3. Verify enabled services match your configuration

## Use Cases

### 1. Security Compliance
Disable backup for services not approved by security policies:

```hcl
resource_type_opt_in_preference = {
  "Aurora" = true   # Approved
  "RDS"    = true   # Approved
  "S3"     = false  # Not approved for automated backup
}
```

### 2. Cost Optimization
Enable only actively used services:

```hcl
resource_type_opt_in_preference = {
  "DynamoDB" = true  # In use
  "EBS"      = true  # In use
  "Neptune"  = false # Not deployed
  "FSx"      = false # Not deployed
}
```

### 3. Gradual Rollout
Enable services incrementally:

```hcl
# Phase 1: Critical databases only
resource_type_opt_in_preference = {
  "Aurora" = true
  "RDS"    = true
  # Other services = false
}

# Phase 2: Add compute and storage
# (Update configuration to enable EC2, EBS, EFS)
```

## Troubleshooting

### Services Not Backing Up

If enabled services aren't being backed up:

1. **Verify region settings:**
   ```bash
   aws backup describe-region-settings
   ```

2. **Check backup plan configuration:**
   Ensure backup plans include selections for enabled services

3. **Review IAM permissions:**
   Verify the backup service role has permissions for enabled services

### Configuration Not Applying

If changes don't take effect:

1. **Wait for propagation:** Region settings changes may take a few minutes
2. **Check for conflicting policies:** AWS Organizations policies may override region settings
3. **Verify provider region:** Ensure Terraform provider is targeting the correct region

## Related Examples

- **[Complete Backup Configuration](../complete_backup/)** - Full backup setup with multiple plans
- **[Cost Optimized Backup](../cost_optimized_backup/)** - Multi-tier backup strategy
- **[Selection by Tags](../selection_by_tags/)** - Dynamic resource selection

## AWS Documentation

- [AWS Backup Region Settings](https://docs.aws.amazon.com/aws-backup/latest/devguide/region-settings.html)
- [Supported Resource Types](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html#supported-resources)
- [Resource Type Management](https://docs.aws.amazon.com/aws-backup/latest/devguide/backup-management.html)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.22.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_region_settings"></a> [region\_settings](#module\_region\_settings) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS region for region settings configuration | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources | `map(string)` | <pre>{<br/>  "Environment": "example",<br/>  "Purpose": "RegionSettings",<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_disabled_services"></a> [disabled\_services](#output\_disabled\_services) | List of AWS services disabled for backup in this region |
| <a name="output_enabled_services"></a> [enabled\_services](#output\_enabled\_services) | List of AWS services enabled for backup in this region |
| <a name="output_region_settings_id"></a> [region\_settings\_id](#output\_region\_settings\_id) | AWS Region where region settings are applied |
| <a name="output_region_settings_summary"></a> [region\_settings\_summary](#output\_region\_settings\_summary) | Complete summary of region settings configuration |
| <a name="output_service_count"></a> [service\_count](#output\_service\_count) | Count of configured services (enabled/disabled/managed) |
<!-- END_TF_DOCS -->
