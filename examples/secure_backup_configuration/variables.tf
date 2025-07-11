# Variables for secure backup configuration

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "secure-backup"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
  
  validation {
    condition     = contains(["prod", "staging", "dev", "test"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev, test."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "security-team"
}

# Security configuration
variable "enable_vault_lock" {
  description = "Enable vault lock for compliance"
  type        = bool
  default     = true
}

variable "vault_lock_changeable_days" {
  description = "Number of days before vault lock becomes permanent"
  type        = number
  default     = 3
  
  validation {
    condition     = var.vault_lock_changeable_days >= 3 && var.vault_lock_changeable_days <= 365
    error_message = "Vault lock changeable days must be between 3 and 365."
  }
}

variable "min_retention_days" {
  description = "Minimum retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.min_retention_days >= 7
    error_message = "Minimum retention days must be at least 7 for compliance."
  }
}

variable "max_retention_days" {
  description = "Maximum retention period in days"
  type        = number
  default     = 2555  # 7 years
  
  validation {
    condition     = var.max_retention_days <= 2555
    error_message = "Maximum retention days cannot exceed 2555 (7 years)."
  }
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 365
  
  validation {
    condition     = var.backup_retention_days >= 30
    error_message = "Backup retention must be at least 30 days."
  }
}

variable "weekly_backup_retention_days" {
  description = "Weekly backup retention period in days"
  type        = number
  default     = 2555  # 7 years
}

variable "enable_continuous_backup" {
  description = "Enable continuous backup for supported resources"
  type        = bool
  default     = true
}

# Cross-region backup configuration
variable "enable_cross_region_backup" {
  description = "Enable cross-region backup for disaster recovery"
  type        = bool
  default     = true
}

variable "cross_region" {
  description = "Cross-region for disaster recovery backups"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.cross_region))
    error_message = "Cross region must be a valid AWS region format (e.g., us-west-2)."
  }
}

# Resource selection
variable "database_resources" {
  description = "List of database resources to backup"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for resource in var.database_resources : can(regex("^arn:aws:", resource))
    ])
    error_message = "All database resources must be valid AWS ARNs."
  }
}

variable "volume_resources" {
  description = "List of volume resources to backup"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for resource in var.volume_resources : can(regex("^arn:aws:", resource))
    ])
    error_message = "All volume resources must be valid AWS ARNs."
  }
}

# Monitoring configuration
variable "notification_email" {
  description = "Email address for backup notifications"
  type        = string
  default     = ""
  
  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 90
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

# Security tags
variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "compliance_framework" {
  description = "Compliance framework this configuration supports"
  type        = string
  default     = "SOC2"
  
  validation {
    condition     = contains(["SOC2", "HIPAA", "PCI-DSS", "ISO27001", "GDPR"], var.compliance_framework)
    error_message = "Compliance framework must be one of: SOC2, HIPAA, PCI-DSS, ISO27001, GDPR."
  }
}