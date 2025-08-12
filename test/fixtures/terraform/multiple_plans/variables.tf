variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
