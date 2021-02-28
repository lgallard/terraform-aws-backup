#
# AWS Backup vault
#
variable "vault_name" {
  description = "Name of the backup vault to create. If not given, AWS use default"
  type        = string
  default     = null
}

variable "vault_kms_key_arn" {
  description = "The server-side encryption key that is used to protect your backups"
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

#
# AWS Backup plan
#
variable "plan_name" {
  description = "The display name of a backup plan"
  type        = string
}

# Default rule
variable "rule_name" {
  description = "An display name for a backup rule"
  type        = string
  default     = null
}

variable "rule_schedule" {
  description = "A CRON expression specifying when AWS Backup initiates a backup job"
  type        = string
  default     = null
}

variable "rule_start_window" {
  description = "The amount of time in minutes before beginning a backup"
  type        = number
  default     = null
}

variable "rule_completion_window" {
  description = "The amount of time AWS Backup attempts a backup before canceling the job and returning an error"
  type        = number
  default     = null
}

variable "rule_recovery_point_tags" {
  description = "Metadata that you can assign to help organize the resources that you create"
  type        = map(string)
  default     = {}
}

# Rule lifecycle
variable "rule_lifecycle_cold_storage_after" {
  description = "Specifies the number of days after creation that a recovery point is moved to cold storage"
  type        = number
  default     = null
}

variable "rule_lifecycle_delete_after" {
  description = "Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than `cold_storage_after`"
  type        = number
  default     = null
}

# Rule copy action
variable "rule_copy_action_lifecycle" {
  description = "The lifecycle defines when a protected resource is copied over to a backup vault and when it expires."
  type        = map
  default     = {}
}

variable "rule_copy_action_destination_vault_arn" {
  description = "An Amazon Resource Name (ARN) that uniquely identifies the destination backup vault for the copied backup."
  type        = string
  default     = null
}


# Rules
variable "rules" {
  description = "A list of rule maps"
  type        = any
  default     = []
}

# Selection
variable "selection_name" {
  description = "The display name of a resource selection document"
  type        = string
  default     = null
}

variable "selection_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan"
  type        = list
  default     = []
}

variable "selection_tag_type" {
  description = "An operation, such as StringEquals, that is applied to a key-value pair used to filter resources in a selection"
  type        = string
  default     = null
}

variable "selection_tag_key" {
  description = "The key in a key-value pair"
  type        = string
  default     = null
}

variable "selection_tag_value" {
  description = "The value in a key-value pair"
  type        = string
  default     = null
}

# Selection
variable "selections" {
  description = "A list of selction maps"
  type        = any
  default     = []
}

variable "enabled" {
  description = "Change to false to avoid deploying any AWS Backup resources"
  type        = bool
  default     = true
}

# Windows Backup parameter
variable "windows_vss_backup" {
  description = "Enable Windows VSS backup option and create a VSS Windows backup"
  type        = bool
  default     = false
}

#
# Notifications
#
variable "notifications" {
  description = "Notification block which defines backup vault events and the SNS Topic ARN to send AWS Backup notifications to. Leave it empty to disable notifications"
  type        = any
  default     = {}
}
