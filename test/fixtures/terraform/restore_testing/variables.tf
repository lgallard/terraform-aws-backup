variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "selection_name" {
  description = "Name of the backup selection"
  type        = string
}

variable "restore_testing_plan_name" {
  description = "Name of the restore testing plan"
  type        = string
}

variable "restore_testing_selection_name" {
  description = "Name of the restore testing selection"
  type        = string
}

variable "restore_testing_schedule" {
  description = "Schedule for restore testing"
  type        = string
  default     = "cron(0 6 ? * SUN *)"
}