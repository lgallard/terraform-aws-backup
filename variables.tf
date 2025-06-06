#
# AWS Backup vault
#
variable "vault_name" {
  description = "Name of the backup vault to create. If not given, AWS use default"
  type        = string
  default     = null

  validation {
    condition     = var.vault_name == null ? true : can(regex("^[0-9A-Za-z-_]{2,50}$", var.vault_name))
    error_message = "The vault_name must be between 2 and 50 characters, and can only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "vault_kms_key_arn" {
  description = "The server-side encryption key that is used to protect your backups"
  type        = string
  default     = null

  validation {
    condition     = var.vault_kms_key_arn == null ? true : can(regex("^arn:aws:kms:", var.vault_kms_key_arn))
    error_message = "The vault_kms_key_arn must be a valid KMS key ARN."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "vault_force_destroy" {
  description = "A boolean that indicates that all recovery points stored in the vault are deleted so that the vault can be destroyed without error"
  type        = bool
  default     = false
}

#
# AWS Backup vault lock configuration
#
variable "locked" {
  description = "Change to true to add a lock configuration for the backup vault"
  type        = bool
  default     = false
}

variable "changeable_for_days" {
  description = "The number of days before the lock date. If omitted creates a vault lock in governance mode, otherwise it will create a vault lock in compliance mode"
  type        = number
  default     = null

  validation {
    condition     = var.changeable_for_days == null ? true : var.changeable_for_days >= 3 && var.changeable_for_days <= 365
    error_message = "The changeable_for_days must be between 3 and 365 days."
  }
}

variable "max_retention_days" {
  description = "The maximum retention period that the vault retains its recovery points"
  type        = number
  default     = null

  validation {
    condition     = var.max_retention_days == null ? true : var.max_retention_days >= 1
    error_message = "The max_retention_days must be greater than or equal to 1."
  }
}

variable "min_retention_days" {
  description = "The minimum retention period that the vault retains its recovery points"
  type        = number
  default     = null

  validation {
    condition     = var.min_retention_days == null ? true : var.min_retention_days >= 1
    error_message = "The min_retention_days must be greater than or equal to 1."
  }
}

#
# AWS Backup plan
#
variable "plan_name" {
  description = "The display name of a backup plan"
  type        = string
  default     = null
}

variable "plans" {
  description = "A map of backup plans to create. Each key is the plan name and each value is a map of plan configuration."
  type = map(object({
    name = optional(string)
    rules = list(object({
      name                     = string
      target_vault_name        = optional(string)
      schedule                 = optional(string)
      start_window             = optional(number)
      completion_window        = optional(number)
      enable_continuous_backup = optional(bool)
      lifecycle = optional(object({
        cold_storage_after = optional(number)
        delete_after       = number
      }))
      recovery_point_tags = optional(map(string))
      copy_actions = optional(list(object({
        destination_vault_arn = string
        lifecycle = optional(object({
          cold_storage_after = optional(number)
          delete_after       = number
        }))
      })), [])
    }))
    selections = optional(map(object({
      resources     = optional(list(string))
      not_resources = optional(list(string))
      conditions    = optional(map(any))
      selection_tags = optional(list(object({
        type  = string
        key   = string
        value = string
      })))
    })), {})
  }))
  default = {}
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

variable "rule_enable_continuous_backup" {
  description = "Enable continuous backups for supported resources."
  type        = bool
  default     = false
}

# Rules
variable "rules" {
  description = "A list of rule maps"
  type = list(object({
    name                     = string
    target_vault_name        = optional(string)
    schedule                 = optional(string)
    start_window             = optional(number)
    completion_window        = optional(number)
    enable_continuous_backup = optional(bool)
    lifecycle = optional(object({
      cold_storage_after = optional(number)
      delete_after       = number
    }))
    recovery_point_tags = optional(map(string))
    copy_actions = optional(list(object({
      destination_vault_arn = string
      lifecycle = optional(object({
        cold_storage_after = optional(number)
        delete_after       = number
      }))
    })), [])
  }))
  default = []
}

# Selection
variable "selection_name" {
  description = "The display name of a resource selection document"
  type        = string
  default     = null
}

variable "selection_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan"
  type        = list(any)
  default     = []
}

variable "selection_not_resources" {
  description = "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to exclude from a backup plan."
  type        = list(any)
  default     = []
}

variable "selection_conditions" {
  description = "A map of conditions that you define to assign resources to your backup plans using tags."
  type        = map(any)
  default     = {}
}

variable "selection_tags" {
  description = "List of tags for `selection_name` var, when using variable definition."
  type        = list(any)
  default     = []
}

# Selection
variable "selections" {
  description = "A list or map of backup selections. If passing a list, each selection must have a name attribute."
  type        = any
  default     = []

  validation {
    condition = can(tomap(var.selections)) || can([
      for s in var.selections : regex("^[a-zA-Z0-9-_]+$", s.name)
    ])
    error_message = "The selections must be either a map with valid keys or a list of objects with valid name attributes."
  }
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

variable "notifications_disable_sns_policy" {
  description = "Disable the creation of the SNS policy. Enable if you need to manage the policy elsewhere."
  type        = bool
  default     = false
}

#
# IAM
#
variable "iam_role_arn" {
  description = "If configured, the module will attach this role to selections, instead of creating IAM resources by itself"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Allow to set IAM role name, otherwise use predefined default"
  type        = string
  default     = ""
}

#
# AWS Backup Report Plan
#
variable "reports" {
  description = "The default cache behavior for this distribution."
  type = list(object({
    name               = string
    description        = optional(string, null)
    formats            = optional(list(string), null)
    s3_bucket_name     = string
    s3_key_prefix      = optional(string, null)
    report_template    = string
    accounts           = optional(list(string), null)
    organization_units = optional(list(string), null)
    regions            = optional(list(string), null)
    framework_arns     = optional(list(string), [])
  }))
  default = []
}

#
# AWS Backup Audit Manager Framework
#
variable "audit_framework" {
  description = "Configuration for AWS Backup Audit Manager framework"
  type = object({
    create      = bool
    name        = string
    description = optional(string)
    controls = list(object({
      name            = string
      parameter_name  = optional(string)
      parameter_value = optional(string)
    }))
  })
  default = {
    create      = false
    name        = null
    description = null
    controls    = []
  }
}

#
# AWS Organizations Backup Policy
#
variable "enable_org_policy" {
  description = "Enable AWS Organizations backup policy"
  type        = bool
  default     = false
}

variable "org_policy_name" {
  description = "Name of the AWS Organizations backup policy"
  type        = string
  default     = "backup-policy"
}

variable "org_policy_description" {
  description = "Description of the AWS Organizations backup policy"
  type        = string
  default     = "AWS Organizations backup policy"
}

variable "org_policy_target_id" {
  description = "Target ID (Root/OU/Account) for the backup policy"
  type        = string
  default     = null
}

variable "backup_policies" {
  description = "Map of backup policies to create"
  type = map(object({
    target_vault_name = string
    schedule          = string
    start_window      = number
    completion_window = number
    lifecycle = object({
      delete_after       = number
      cold_storage_after = optional(number)
    })
    recovery_point_tags      = optional(map(string))
    copy_actions             = optional(list(map(string)))
    enable_continuous_backup = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in var.backup_policies : can(regex("^cron\\([^)]+\\)|rate\\([^)]+\\)$", policy.schedule))
    ])
    error_message = "The schedule must be a valid cron or rate expression."
  }

  validation {
    condition = alltrue([
      for policy in var.backup_policies : policy.start_window >= 60 && policy.start_window <= 43200
    ])
    error_message = "The start_window must be between 60 minutes (1 hour) and 43200 minutes (30 days)."
  }
}

variable "backup_selections" {
  description = "Map of backup selections"
  type = map(object({
    resources     = optional(list(string))
    not_resources = optional(list(string))
    conditions    = optional(map(any))
    tags          = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for selection in var.backup_selections : selection.resources == null || alltrue([
        for resource in selection.resources : can(regex("^arn:aws:", resource))
      ])
    ])
    error_message = "All resources must be valid AWS ARNs."
  }
}

variable "advanced_backup_settings" {
  description = "Advanced backup settings by resource type"
  type        = map(map(string))
  default     = {}
}

variable "backup_regions" {
  description = "List of regions where backups should be created"
  type        = list(string)
  default     = []
}
