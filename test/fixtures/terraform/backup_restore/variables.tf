variable "resource_prefix" {
  description = "Prefix for all test resources"
  type        = string
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "enable_continuous_backup" {
  description = "Enable continuous backup for supported resources"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "test_data_content" {
  description = "Test data content for validation"
  type        = string
  default     = "backup-restore-test-data"
}
