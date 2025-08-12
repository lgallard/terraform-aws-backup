variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "plan_name" {
  description = "Plan name"
  type        = string
  default     = "conditions-backup-plan"
}

variable "vault_name" {
  description = "Vault name"
  type        = string
  default     = "conditions-backup-vault"
}
