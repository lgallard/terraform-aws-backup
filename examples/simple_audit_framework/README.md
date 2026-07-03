<!-- BEGIN_TF_DOCS -->
# AWS Backup Audit Framework Example

This example demonstrates how to create an AWS Backup Audit Framework with various controls and their configurations.

## Features

- Creates an AWS Backup Audit Framework
- Configures multiple audit controls with different parameters
- Demonstrates a control scope that targets a specific resource type
- Demonstrates parameter handling for controls with and without parameters
- Shows how to properly configure framework tags

## Usage

```hcl
# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Audit Framework
  audit_framework = {
    create      = true
    name        = "exampleFramework"
    description = "this is an example framework"

    controls = [
      # Vault lock check - ensures resources are protected by vault lock
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
        parameter_name  = "maxRetentionDays"
        parameter_value = "100" # Maximum retention period allowed by vault lock
        scope = {
          compliance_resource_types = ["EBS"]
        }
      },
    ]
  }

  # Tags are now specified separately
  tags = {
    Name = "Example Framework"
  }
}
```

## Controls Configuration

This example includes several controls:

1. **BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK**
   - Ensures recovery points meet minimum retention period
   - Parameter: requiredRetentionDays = 35

2. **BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK**
   - Ensures regular backups with minimum retention
   - Parameter: requiredRetentionDays = 35

3. **BACKUP_RECOVERY_POINT_ENCRYPTED**
   - Ensures recovery points are encrypted
   - No parameters required

4. **BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED**
   - Prevents manual deletion of recovery points
   - No parameters required

5. **BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK**
   - Ensures resources are protected by vault lock
   - Parameter: maxRetentionDays = 100
   - Scope: EBS resources

6. **BACKUP_LAST_RECOVERY_POINT_CREATED**
   - Monitors recent backup creation
   - Parameter: recoveryPointAgeUnit = days

## Notes

1. Some controls don't accept parameters and should omit parameter_name and parameter_value
2. The framework creation can take up to 20 minutes
3. Control scopes can target resource types, resource IDs, or a single tag key/value pair
4. Tags are applied at the framework level
5. Framework policy assignments must be managed through AWS Console or AWS CLI
6. **Important:** For the Deployment Status of the Framework to be successful, you must enable AWS Config resource tracking to monitor configuration changes of your backup resources. This can be done from the AWS Console.
<!-- END_TF_DOCS -->
