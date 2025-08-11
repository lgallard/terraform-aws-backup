variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "selection_name" {
  description = "Name of the backup selection"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
