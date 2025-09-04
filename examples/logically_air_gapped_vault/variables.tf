#
# Variables for Simple Backup plan with Logically Air Gapped Vault
#

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault to create"
  type        = string
  default     = "compliance-air-gapped-vault"
}

variable "min_retention_days" {
  description = "Minimum retention period that the vault retains its recovery points"
  type        = number
  default     = 7  # AWS minimum, allows for flexible compliance needs

  validation {
    condition     = var.min_retention_days >= 7 && var.min_retention_days <= 2555
    error_message = "The min_retention_days must be between 7 and 2555 days (minimum 7 days for compliance requirements)."
  }
}

variable "max_retention_days" {
  description = "Maximum retention period that the vault retains its recovery points"
  type        = number
  default     = 2555  # 7 years for compliance - configurable for different compliance needs

  validation {
    condition     = var.max_retention_days >= 1 && var.max_retention_days <= 2555
    error_message = "The max_retention_days must be between 1 and 2555 days (7 years maximum for compliance)."
  }

  validation {
    condition     = var.min_retention_days <= var.max_retention_days
    error_message = "The min_retention_days must be less than or equal to max_retention_days."
  }
}

variable "plan_name" {
  description = "The display name of a backup plan"
  type        = string
  default     = "compliance-backup-plan"
}

variable "rule_name" {
  description = "An display name for a backup rule"
  type        = string
  default     = "daily-backup-rule"
}

variable "rule_schedule" {
  description = "A CRON expression specifying when AWS Backup initiates a backup job"
  type        = string
  default     = "cron(0 1 ? * * *)"  # Daily at 1 AM
}

variable "selection_name" {
  description = "The display name of a resource selection document"
  type        = string
  default     = "selection"
}

variable "selection_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan"
  type        = list(string)
  default = [
    "arn:aws:dynamodb:*:*:table/*",
    "arn:aws:ec2:*:*:volume/*",
    "arn:aws:rds:*:*:db:*"
  ]
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default = {
    Environment = "production"
    Purpose     = "compliance"
    Compliance  = "SOX"
    Owner       = "data-governance-team"
  }
}