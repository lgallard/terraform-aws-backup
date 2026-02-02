# Variables for Cross-Account Backup Vault Policy Example

variable "source_account_ids" {
  description = "List of source AWS account IDs that are allowed to copy backups to this vault"
  type        = list(string)
  default     = ["123456789012", "987654321098"]

  validation {
    condition = alltrue([
      for account_id in var.source_account_ids :
      can(regex("^[0-9]{12}$", account_id))
    ])
    error_message = "All account IDs must be exactly 12 digits."
  }
}

variable "allowed_source_regions" {
  description = "List of AWS regions from which cross-account backup copies are allowed"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]

  validation {
    condition = alltrue([
      for region in var.allowed_source_regions :
      can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", region))
    ])
    error_message = "All regions must be valid AWS region names (e.g., us-east-1, eu-west-1)."
  }
}

variable "audit_role_arn" {
  description = "ARN of the audit role that can access the backup vault for compliance purposes"
  type        = string
  default     = "arn:aws:iam::999999999999:role/AWSBackupAuditRole"

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/", var.audit_role_arn))
    error_message = "The audit_role_arn must be a valid IAM role ARN."
  }
}

variable "vault_name_prefix" {
  description = "Prefix for the backup vault name (random suffix will be added)"
  type        = string
  default     = "dr-vault"

  validation {
    condition     = can(regex("^[0-9A-Za-z-_]{2,40}$", var.vault_name_prefix))
    error_message = "The vault_name_prefix must be 2-40 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "enable_vault_lock" {
  description = "Enable vault lock for compliance. When enabled, backups cannot be deleted before the retention period expires"
  type        = bool
  default     = true
}

variable "min_retention_days" {
  description = "Minimum retention period in days for backup vault lock"
  type        = number
  default     = 30

  validation {
    condition     = var.min_retention_days >= 7 && var.min_retention_days <= 2555
    error_message = "The min_retention_days must be between 7 and 2555 days."
  }
}

variable "max_retention_days" {
  description = "Maximum retention period in days for backup vault lock"
  type        = number
  default     = 365

  validation {
    condition     = var.max_retention_days >= 7 && var.max_retention_days <= 2555
    error_message = "The max_retention_days must be between 7 and 2555 days."
  }
}

variable "lock_changeable_for_days" {
  description = "Number of days before the vault lock becomes immutable (compliance mode). Use null for governance mode only"
  type        = number
  default     = 7

  validation {
    condition     = var.lock_changeable_for_days == null || (var.lock_changeable_for_days >= 3 && var.lock_changeable_for_days <= 365)
    error_message = "The lock_changeable_for_days must be between 3 and 365 days or null."
  }
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic rotation of the KMS key used for vault encryption"
  type        = bool
  default     = true
}

variable "cold_storage_after_days" {
  description = "Number of days after backup creation to move to cold storage"
  type        = number
  default     = 30

  validation {
    condition     = var.cold_storage_after_days >= 30
    error_message = "The cold_storage_after_days must be at least 30 days (AWS requirement)."
  }
}

variable "delete_after_days" {
  description = "Number of days after backup creation to delete the backup"
  type        = number
  default     = 365

  validation {
    condition     = var.delete_after_days >= 1
    error_message = "The delete_after_days must be at least 1 day."
  }
}
