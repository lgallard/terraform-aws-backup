variable "audit_framework_name" {
  description = "Name of the audit framework"
  type        = string
  default     = "enterprise-audit-framework"
}

variable "audit_framework_description" {
  description = "Description of the audit framework"
  type        = string
  default     = "Enterprise-wide AWS Backup Audit Framework with comprehensive controls"
}

variable "retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 35
}

variable "resource_types" {
  description = "Types of resources to monitor"
  type        = map(string)
  default = {
    all = "ALL"
    rds = "RDS"
  }
}

variable "frequency_unit" {
  description = "Required frequency unit for backups"
  type        = string
  default     = "hours"
}

variable "backup_regions" {
  description = "AWS regions for backup policies"
  type        = list(string)
  default     = ["us-west-2", "us-east-1", "eu-west-1"]
}

variable "organizational_units" {
  description = "List of organizational unit IDs"
  type        = list(string)
  default = [
    "ou-abcd-12345678",
    "ou-efgh-87654321"
  ]
}

variable "backup_policy_id" {
  description = "ID of the backup policy to assign"
  type        = string
  default     = "backup-policy-id"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for backup encryption"
  type        = string
  default     = "arn:aws:kms:us-west-2:123456789101:key/abcd1234-ab12-cd34-ef56-abcdef123456"
}

variable "report_bucket" {
  description = "S3 bucket for backup reports"
  type        = string
  default     = "my-backup-reports-bucket"
}

variable "account_ids" {
  description = "List of AWS account IDs to include in reports"
  type        = list(string)
  default     = ["123456789101", "987654321098"]
}
