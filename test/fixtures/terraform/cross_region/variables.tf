variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "source_region" {
  description = "Source AWS region"
  type        = string
  default     = "us-east-1"
}

variable "destination_region" {
  description = "Destination AWS region"
  type        = string
  default     = "us-west-2"
}