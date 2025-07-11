variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}