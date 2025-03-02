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
      },
    ]
  }

  # Tags are now specified separately
  tags = {
    Name = "Example Framework"
  }
}
