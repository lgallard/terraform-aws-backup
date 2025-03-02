<!-- BEGIN_TF_DOCS -->
# Organization Backup Policy Example

This example demonstrates how to create an AWS Backup configuration that implements organization backup policies. It showcases how to:

- Create backup policies for different types of systems (critical and standard)
- Implement tag-based backup selection strategies
- Configure backup vaults with appropriate retention settings
- Set up cross-region backup copies for disaster recovery
- Apply resource tagging for organization and management

## Organization Backup Strategy

This example implements a comprehensive backup strategy for an organization with:

### Critical Systems (High Criticality)
- Daily backups executed at 5 AM
- 30-day transition to cold storage for cost optimization
- 365-day retention period for long-term compliance
- Cross-region backup copies for disaster recovery
- Tagged with "Criticality = high"

### Standard Systems
- Daily backups at 5 AM
- Direct deletion after 90 days (no cold storage)
- Cross-region backup copies with matching lifecycle
- Tagged with "Criticality = standard"

## Vault Configuration

The backup vault is configured with:
- Minimum retention period: 7 days
- Maximum retention period: 365 days
- Ensures compliance with organization's data retention policies

## Resource Selection

Resources are selected for backup based on tags:
- Critical systems are identified by tag "Criticality = high"
- Standard systems are identified by tag "Criticality = standard"
- This allows for automatic backup policy assignment based on system classification

## Example Usage

```hcl
module "aws_backup_example" {
  source = "../.."

  # Backup Plan configuration
  plan_name = "organization_backup_plan"

  # Vault configuration
  vault_name         = "organization_backup_vault"
  min_retention_days = 7
  max_retention_days = 365

  rules = [
    {
      name                     = "critical_systems"
      target_vault_name        = "critical_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 365
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "high"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 365
          }
        }
      ]
    },
    {
      name                     = "standard_systems"
      target_vault_name        = "standard_systems_vault"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
      recovery_point_tags = {
        Environment = "prod"
        Criticality = "standard"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 0
            delete_after       = 90
          }
        }
      ]
    }
  ]

  # Selection configuration
  selections = [
    {
      name = "critical_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "high"
      }
    },
    {
      name = "standard_systems"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Criticality"
        value = "standard"
      }
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "organization_backup"
  }
}
```

## Implementation Notes

1. **Backup Rules**:
   - Each rule has specific windows for backup operations
   - Start window: 480 minutes (8 hours)
   - Completion window: 561 minutes (9.35 hours)
   - Continuous backup is disabled for both rule sets

2. **Copy Actions**:
   - Both rules include cross-region copies
   - Copies maintain the same lifecycle rules as source backups
   - Secondary vault is in us-east-1 region

3. **Resource Tags**:
   - Environment tagging for production systems
   - Project-specific tags for resource management
   - Criticality tags for backup policy assignment
<!-- END_TF_DOCS -->
