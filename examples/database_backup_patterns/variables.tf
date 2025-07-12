# Database Backup Patterns Variables

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
  default     = "database-backup-vault"
}

variable "vault_kms_key_arn" {
  description = "KMS key ARN for vault encryption"
  type        = string
  default     = null
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

# Database resource configurations
variable "critical_rds_resources" {
  description = "List of critical RDS database ARNs requiring frequent backups"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:db:prod-primary-*",
    "arn:aws:rds:*:*:cluster:prod-aurora-*"
  ]
}

variable "standard_rds_resources" {
  description = "List of standard RDS database ARNs"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:db:app-*",
    "arn:aws:rds:*:*:cluster:staging-*"
  ]
}

variable "dynamodb_resources" {
  description = "List of DynamoDB table ARNs"
  type        = list(string)
  default = [
    "arn:aws:dynamodb:*:*:table/user-*",
    "arn:aws:dynamodb:*:*:table/session-*",
    "arn:aws:dynamodb:*:*:table/analytics-*"
  ]
}

variable "development_db_resources" {
  description = "List of development database ARNs"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:db:dev-*",
    "arn:aws:dynamodb:*:*:table/dev-*"
  ]
}

# DocumentDB resources
variable "documentdb_resources" {
  description = "List of DocumentDB cluster ARNs"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:cluster:docdb-*"
  ]
}

# Monitoring and alerting
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alerting"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for backup failure alerts"
  type        = string
  default     = null
}

variable "enable_backup_validation" {
  description = "Enable automated backup validation with Lambda"
  type        = bool
  default     = false
}

# Backup frequency configurations
variable "critical_backup_frequency" {
  description = "Backup frequency for critical databases (cron expression)"
  type        = string
  default     = "cron(0 */6 * * ? *)" # Every 6 hours
  
  validation {
    condition     = can(regex("^cron\\(", var.critical_backup_frequency))
    error_message = "Critical backup frequency must be a valid cron expression."
  }
}

variable "standard_backup_frequency" {
  description = "Backup frequency for standard databases (cron expression)"
  type        = string
  default     = "cron(0 3 * * ? *)" # Daily at 3 AM
  
  validation {
    condition     = can(regex("^cron\\(", var.standard_backup_frequency))
    error_message = "Standard backup frequency must be a valid cron expression."
  }
}

# Retention policies
variable "critical_retention_days" {
  description = "Retention period for critical database backups"
  type        = number
  default     = 90
  
  validation {
    condition     = var.critical_retention_days >= 7 && var.critical_retention_days <= 365
    error_message = "Critical retention days must be between 7 and 365."
  }
}

variable "standard_retention_days" {
  description = "Retention period for standard database backups"
  type        = number
  default     = 180
  
  validation {
    condition     = var.standard_retention_days >= 7 && var.standard_retention_days <= 365
    error_message = "Standard retention days must be between 7 and 365."
  }
}

variable "development_retention_days" {
  description = "Retention period for development database backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.development_retention_days >= 7 && var.development_retention_days <= 90
    error_message = "Development retention days must be between 7 and 90."
  }
}

# Cold storage configuration
variable "enable_cold_storage" {
  description = "Enable cold storage transition for cost optimization"
  type        = bool
  default     = true
}

variable "cold_storage_after_days" {
  description = "Days after which to move backups to cold storage"
  type        = number
  default     = 30
  
  validation {
    condition     = var.cold_storage_after_days == 0 || var.cold_storage_after_days >= 30
    error_message = "Cold storage after days must be 0 (disabled) or at least 30."
  }
}

# Performance settings
variable "backup_windows" {
  description = "Backup window configurations for different database tiers"
  type = object({
    critical = object({
      start_window      = number
      completion_window = number
    })
    standard = object({
      start_window      = number
      completion_window = number
    })
    development = object({
      start_window      = number
      completion_window = number
    })
  })
  default = {
    critical = {
      start_window      = 60  # 1 hour
      completion_window = 240 # 4 hours
    }
    standard = {
      start_window      = 120 # 2 hours
      completion_window = 360 # 6 hours
    }
    development = {
      start_window      = 180 # 3 hours
      completion_window = 480 # 8 hours
    }
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "example"
    Purpose     = "DatabaseBackup"
  }
}