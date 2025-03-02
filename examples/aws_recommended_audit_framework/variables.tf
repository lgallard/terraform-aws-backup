variable "audit_config" {
  description = "AWS recommended Backup Audit Framework configuration"
  type = object({
    framework = object({
      name        = string
      description = string
    })
    controls = object({
      backup_plan = object({
        min_retention_days = number
        max_retention_days = optional(number)
        frequency_unit     = string
        frequency_value    = number
      })
      resource_types = map(string)
      regions        = list(string)
    })
    policy = object({
      id                   = string
      organizational_units = list(string)
    })
    vault = object({
      name           = string
      kms_key_arn    = string
      force_destroy  = bool
      lock_retention = optional(number)
    })
    reporting = object({
      bucket_name = string
      account_ids = list(string)
      formats     = list(string)
    })
  })

  default = {
    framework = {
      name        = "aws-recommended-framework"
      description = "AWS recommended backup framework following best practices"
    }
    controls = {
      backup_plan = {
        min_retention_days = 30  # AWS recommends minimum 30 days retention
        max_retention_days = 365 # Optional maximum retention period
        frequency_unit     = "days"
        frequency_value    = 1 # Daily backups
      }
      resource_types = {
        ebs    = "EBS"    # Critical data volumes
        rds    = "RDS"    # Databases
        s3     = "S3"     # Important buckets
        ddb    = "DDB"    # DynamoDB tables
        efs    = "EFS"    # File systems
        ec2    = "EC2"    # Critical instances
        aurora = "Aurora" # Aurora clusters
      }
      regions = [
        "us-east-1", # Primary region
        "us-west-2"  # DR region
      ]
    }
    policy = {
      id                   = "aws-backup-policy"
      organizational_units = ["*"] # Apply to all OUs
    }
    vault = {
      name           = "aws-recommended-vault"
      kms_key_arn    = null # Must be provided
      force_destroy  = false
      lock_retention = 90 # Optional: Lock vault for compliance
    }
    reporting = {
      bucket_name = null  # Must be provided
      account_ids = ["*"] # All accounts in organization
      formats     = ["CSV", "JSON"]
    }
  }

  validation {
    condition     = var.audit_config.controls.backup_plan.min_retention_days >= 30
    error_message = "Minimum retention period must be at least 30 days per AWS recommendations."
  }

  validation {
    condition     = var.audit_config.controls.backup_plan.frequency_value <= 1
    error_message = "Backup frequency should be at least daily per AWS recommendations."
  }
}
