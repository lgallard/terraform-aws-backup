# Cross-Region Backup Variables

variable "primary_region" {
  description = "Primary AWS region for backup vault"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for backup replication"
  type        = string
  default     = "us-west-2"
}

variable "vault_name" {
  description = "Name of the primary backup vault"
  type        = string
  default     = "cross-region-backup-vault"
}

variable "primary_vault_kms_key_arn" {
  description = "KMS key ARN for primary vault encryption"
  type        = string
  default     = null
}

variable "secondary_vault_kms_key_arn" {
  description = "KMS key ARN for secondary vault encryption"
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

variable "backup_resources" {
  description = "List of resource ARNs to backup"
  type        = list(string)
  default = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:rds:*:*:db:*",
    "arn:aws:rds:*:*:cluster:*",
    "arn:aws:dynamodb:*:*:table/*",
    "arn:aws:elasticfilesystem:*:*:file-system/*"
  ]
}

variable "enable_notifications" {
  description = "Enable SNS notifications for backup events"
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "example"
    Purpose     = "CrossRegionBackup"
  }
}