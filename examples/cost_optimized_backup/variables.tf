# Cost-Optimized Backup Variables

variable "region" {
  description = "AWS region for backup resources"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
  default     = "cost-optimized-backup-vault"
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

variable "critical_resources" {
  description = "List of critical resource ARNs to backup with high frequency"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:db:production-*",
    "arn:aws:rds:*:*:cluster:production-*",
    "arn:aws:dynamodb:*:*:table/production-*"
  ]
}

variable "standard_resources" {
  description = "List of standard resource ARNs to backup with daily frequency"
  type        = list(string)
  default = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:rds:*:*:db:staging-*",
    "arn:aws:elasticfilesystem:*:*:file-system/*"
  ]
}

variable "development_resources" {
  description = "List of development resource ARNs to backup with weekly frequency"
  type        = list(string)
  default = [
    "arn:aws:rds:*:*:db:dev-*",
    "arn:aws:dynamodb:*:*:table/dev-*"
  ]
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform    = "true"
    Environment  = "example"
    Purpose      = "CostOptimizedBackup"
    CostStrategy = "MultiTier"
  }
}
