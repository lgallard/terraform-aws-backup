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
  selections = [
    {
      name = "resource_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "prod"
      }
      resources = [
        "arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
        "arn:aws:ec2:us-west-2:123456789012:volume/vol-12345678"
      ]
    }
  ]

  # Enable AWS recommended backup framework
  audit_framework = {
    create      = true
    name        = "aws_recommended_framework"
    description = "AWS Recommended Backup Framework"
    control_scope = {
      tags = {
        Environment = "prod"
      }
    }
    controls = [
      {
        control_name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        name         = "backup_resources_protected_by_backup_plan"
        input_parameters = [
          {
            parameter_name  = "requiredBackupPlanFrequencyUnit"
            parameter_value = "hours"
          },
          {
            parameter_name  = "requiredBackupPlanFrequencyValue"
            parameter_value = "24"
          },
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        name         = "backup_plan_min_frequency_and_retention"
        input_parameters = [
          {
            parameter_name  = "requiredFrequencyUnit"
            parameter_value = "hours"
          },
          {
            parameter_name  = "requiredFrequencyValue"
            parameter_value = "24"
          },
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
        name         = "backup_recovery_point_min_retention"
        input_parameters = [
          {
            parameter_name  = "requiredRetentionDays"
            parameter_value = "35"
          }
        ]
      },
      {
        control_name     = "BACKUP_RECOVERY_POINT_ENCRYPTED"
        name             = "backup_recovery_point_encrypted"
        input_parameters = []
      },
      {
        control_name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
        name         = "backup_resources_protected_by_vault_lock"
        input_parameters = [
          {
            parameter_name  = "maxRetentionDays"
            parameter_value = "100"
          }
        ]
      }
    ]

    policy_assignment = {
      opt_in_preference       = true
      policy_id               = "backup-policy-id"
      regions                 = ["us-west-2"]
      organizational_unit_ids = ["ou-1234-12345678"]
    }
  }

  # Configure comprehensive backup reports
  reports = [
    {
      name            = "aws_backup_audit_report"
      description     = "AWS Backup compliance and audit report"
      report_template = "BACKUP_JOB_REPORT"
      s3_bucket_name  = "my-backup-reports-bucket"
      s3_key_prefix   = "backup_audit"
      formats         = ["CSV", "JSON"]
      framework_arns  = ["arn:aws:backup:us-west-2:123456789012:framework/aws_recommended_framework"]
    }
  ]

  tags = {
    Environment = "prod"
    Project     = "backup_audit"
    Framework   = "aws_recommended"
    Compliance  = "enabled"
    Encryption  = "enabled"
    CrossRegion = "enabled"
  }
}
