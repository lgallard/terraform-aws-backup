# Backup Selection Data Source Variables

variable "region" {
  description = "AWS region for backup resources"
  type        = string
  default     = "us-east-1"
}

variable "vault_name" {
  description = "Name of the backup vault"
  type        = string
  default     = "backup-selection-datasource-vault"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "example"
    Purpose     = "BackupSelectionDataSource"
  }
}

# Optional: Variables for querying existing backup selections
# Uncomment to use:

# variable "existing_plan_id" {
#   description = "ID of an existing backup plan to query"
#   type        = string
#   default     = ""
# }

# variable "existing_selection_id" {
#   description = "ID of an existing backup selection to query"
#   type        = string
#   default     = ""
# }
