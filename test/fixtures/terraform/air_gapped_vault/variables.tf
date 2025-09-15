variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault to create"
  type        = string
}

variable "vault_type" {
  description = "Type of backup vault to create"
  type        = string
  default     = "logically_air_gapped"
}

variable "min_retention_days" {
  description = "Minimum retention period that the vault retains its recovery points"
  type        = number
  default     = 7
}

variable "max_retention_days" {
  description = "Maximum retention period that the vault retains its recovery points"
  type        = number
  default     = 30
}

variable "plan_name" {
  description = "The display name of a backup plan"
  type        = string
}

variable "selection_name" {
  description = "The display name of a resource selection document"
  type        = string
}
