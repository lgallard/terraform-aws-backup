# Compliance Backup Variables

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev."
  }
}

variable "compliance_framework" {
  description = "Compliance framework to implement (SOC2, HIPAA, PCI, ISO27001, GDPR)"
  type        = string
  default     = "SOC2"
  
  validation {
    condition     = contains(["SOC2", "HIPAA", "PCI", "ISO27001", "GDPR"], var.compliance_framework)
    error_message = "Compliance framework must be one of: SOC2, HIPAA, PCI, ISO27001, GDPR."
  }
}

# Vault configuration
variable "vault_name" {
  description = "Name of the compliance backup vault"
  type        = string
  default     = "compliance-backup-vault"
}

# Vault lock configuration
variable "enable_vault_lock" {
  description = "Enable vault lock for compliance (immutable backups)"
  type        = bool
  default     = true
}

variable "min_retention_days" {
  description = "Minimum retention period (compliance requirement)"
  type        = number
  default     = 90
  
  validation {
    condition     = var.min_retention_days >= 7 && var.min_retention_days <= 2555
    error_message = "Minimum retention days must be between 7 and 2555 (7 years)."
  }
}

variable "max_retention_days" {
  description = "Maximum retention period (compliance requirement)"
  type        = number
  default     = 2555 # 7 years
  
  validation {
    condition     = var.max_retention_days >= 7 && var.max_retention_days <= 2555
    error_message = "Maximum retention days must be between 7 and 2555 (7 years)."
  }
}

variable "changeable_for_days" {
  description = "Days before vault lock becomes immutable (compliance mode)"
  type        = number
  default     = 3
  
  validation {
    condition     = var.changeable_for_days >= 3 && var.changeable_for_days <= 365
    error_message = "Changeable for days must be between 3 and 365."
  }
}

variable "retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 2555 # 7 years for long-term compliance
  
  validation {
    condition     = var.retention_days >= 7 && var.retention_days <= 2555
    error_message = "Retention days must be between 7 and 2555."
  }
}

# KMS configuration
variable "kms_deletion_window_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

# Backup configuration
variable "backup_schedule" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = "cron(0 1 * * ? *)" # Daily at 1 AM
  
  validation {
    condition     = can(regex("^cron\\([^)]+\\)$", var.backup_schedule))
    error_message = "Backup schedule must be a valid cron expression."
  }
}

variable "backup_start_window" {
  description = "Backup start window in minutes"
  type        = number
  default     = 60
  
  validation {
    condition     = var.backup_start_window >= 60 && var.backup_start_window <= 43200
    error_message = "Backup start window must be between 60 minutes and 43200 minutes (30 days)."
  }
}

variable "backup_completion_window" {
  description = "Backup completion window in minutes"
  type        = number
  default     = 240
  
  validation {
    condition     = var.backup_completion_window >= 120 && var.backup_completion_window <= 43200
    error_message = "Backup completion window must be between 120 minutes and 43200 minutes (30 days)."
  }
}

variable "cold_storage_after_days" {
  description = "Days after which to move backups to cold storage"
  type        = number
  default     = 90
  
  validation {
    condition     = var.cold_storage_after_days == 0 || var.cold_storage_after_days >= 30
    error_message = "Cold storage after days must be 0 (disabled) or at least 30."
  }
}

# Resource selection
variable "backup_resources" {
  description = "List of resource ARNs to backup for compliance"
  type        = list(string)
  default = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:rds:*:*:db:*",
    "arn:aws:rds:*:*:cluster:*",
    "arn:aws:dynamodb:*:*:table/*",
    "arn:aws:elasticfilesystem:*:*:file-system/*",
    "arn:aws:s3:::*"
  ]
}

# Audit framework configuration
variable "enable_audit_framework" {
  description = "Enable AWS Backup Audit Manager framework"
  type        = bool
  default     = true
}

variable "base_audit_controls" {
  description = "Base audit controls for all compliance frameworks"
  type = list(object({
    name            = string
    parameter_name  = optional(string)
    parameter_value = optional(string)
  }))
  default = [
    {
      name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
    },
    {
      name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
      parameter_name  = "requiredFrequencyUnit"
      parameter_value = "days"
    },
    {
      name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
    },
    {
      name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
      parameter_name  = "maxRetentionDays"
      parameter_value = "2555"
    }
  ]
}

variable "soc2_controls" {
  description = "SOC2 specific audit controls"
  type = list(object({
    name            = string
    parameter_name  = optional(string)
    parameter_value = optional(string)
  }))
  default = [
    {
      name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
      parameter_name  = "requiredRetentionDays"
      parameter_value = "90"
    }
  ]
}

variable "hipaa_controls" {
  description = "HIPAA specific audit controls"
  type = list(object({
    name            = string
    parameter_name  = optional(string)
    parameter_value = optional(string)
  }))
  default = [
    {
      name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
      parameter_name  = "requiredRetentionDays"
      parameter_value = "2555"
    },
    {
      name = "BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED"
    }
  ]
}

variable "pci_controls" {
  description = "PCI DSS specific audit controls"
  type = list(object({
    name            = string
    parameter_name  = optional(string)
    parameter_value = optional(string)
  }))
  default = [
    {
      name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
      parameter_name  = "requiredRetentionDays"
      parameter_value = "365"
    }
  ]
}

variable "custom_audit_controls" {
  description = "Custom audit controls for specific requirements"
  type = list(object({
    name            = string
    parameter_name  = optional(string)
    parameter_value = optional(string)
  }))
  default = []
}

# Monitoring and alerting
variable "enable_notifications" {
  description = "Enable SNS notifications for backup events"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerts"
  type        = bool
  default     = true
}

variable "enable_dashboard" {
  description = "Enable CloudWatch dashboard for compliance monitoring"
  type        = bool
  default     = true
}

# Reporting configuration
variable "enable_reports" {
  description = "Enable automated compliance reports"
  type        = bool
  default     = true
}

variable "reports_s3_bucket" {
  description = "S3 bucket name for compliance reports"
  type        = string
  default     = null
}

variable "report_regions" {
  description = "List of regions to include in compliance reports"
  type        = list(string)
  default     = ["us-east-1"]
}

# Audit logging
variable "enable_cloudtrail" {
  description = "Enable CloudTrail for backup audit logging"
  type        = bool
  default     = false
}

variable "audit_s3_bucket_name" {
  description = "S3 bucket name for CloudTrail audit logs"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "example"
    Purpose     = "ComplianceBackup"
  }
}