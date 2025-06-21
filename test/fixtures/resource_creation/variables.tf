variable "table_name" {
  description = "Name of the test DynamoDB table"
  type        = string
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
}

variable "plan_name" {
  description = "Name of the backup plan"
  type        = string
}