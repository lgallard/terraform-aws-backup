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
