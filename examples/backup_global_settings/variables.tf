# Optional variables for customizing the example

variable "vault_name" {
  description = "Name of the backup vault to create"
  type        = string
  default     = "centralized-backup-vault"
}

variable "enable_cross_account_backup" {
  description = "Enable cross-account backup functionality"
  type        = bool
  default     = true
}

variable "enable_mpa" {
  description = "Enable AWS Backup Multi-Party Authorization (MPA)"
  type        = bool
  default     = false
}

variable "enable_delegated_administrator" {
  description = "Enable AWS Backup delegated administrator integration"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron expression for backup schedule"
  type        = string
  default     = "cron(0 2 * * ? *)" # Daily at 2 AM
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "tags" {
  description = "A mapping of tags to assign to resources"
  type        = map(string)
  default = {
    Owner            = "backup-team"
    Environment      = "production"
    BackupGovernance = "centralized"
    Terraform        = true
  }
}
