module "aws_backup_example" {
  source = "../.."

  # Vault configuration with encryption and compliance settings
  vault_name          = "aws_backup_vault"
  vault_kms_key_arn   = "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  vault_force_destroy = true
  min_retention_days  = 7
  max_retention_days  = 360
  locked              = true
  changeable_for_days = 3

  # Backup plan configuration
  plan_name = "aws_recommended_backup_plan"

  # Backup rules configuration
  rules = [
    {
      name                     = "rule_1"
      schedule                 = "cron(0 5 ? * * *)"
      start_window             = 480
      completion_window        = 561
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 180
      }
      recovery_point_tags = {
        Environment = "prod"
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:123456789012:backup-vault:secondary_vault"
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 180
          }
        }
      ]
    }
  ]

  # Backup selection configuration
  selections = {
    resource_selection = {
      name = "resource_selection"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        }
      ]
      resources = [
        "arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
        "arn:aws:ec2:us-west-2:123456789012:volume/vol-12345678"
      ]
    }
  }

  # Enable AWS recommended backup framework
  audit_framework = {
    create      = true
    name        = "aws_recommended_framework"
    description = "AWS Recommended Backup Framework"
    controls = [
      {
        name            = "backup_resources_protected_by_backup_plan"
        parameter_name  = "requiredRetentionDays"
        parameter_value = "35"
      },
      {
        name            = "backup_plan_min_frequency_and_retention"
        parameter_name  = "requiredRetentionDays"
        parameter_value = "35"
      },
      {
        name            = "backup_recovery_point_min_retention"
        parameter_name  = "requiredRetentionDays"
        parameter_value = "35"
      },
      {
        name = "backup_recovery_point_encrypted"
      },
      {
        name            = "backup_resources_protected_by_vault_lock"
        parameter_name  = "maxRetentionDays"
        parameter_value = "100"
      }
    ]
  }


  tags = {
    Environment = "prod"
    Project     = "backup_audit"
    Framework   = "aws_recommended"
    Compliance  = "enabled"
    Encryption  = "enabled"
    CrossRegion = "enabled"
  }
}
