#
# Simple Backup plan with Logically Air Gapped Vault
#

provider "aws" {
  region = var.aws_region

  # Note: The following settings are for development/testing only
  # Remove these in production to ensure proper validation
  # skip_metadata_api_check     = true
  # skip_region_validation      = true
  # skip_credentials_validation = true
}

# Simple plan
module "aws_backup_plan" {
  source = "../../"

  # Vault configuration - Air Gapped
  vault_name         = var.vault_name
  vault_type         = "logically_air_gapped"
  vault_kms_key_arn  = var.vault_kms_key_arn
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days

  # Plan configuration
  plan_name = var.plan_name

  # Rule configuration
  # Use `rules` instead of the single `rule_*` inputs to demonstrate
  # primary logically air-gapped vault targets and malware scan actions.
  rules = [
    {
      name                                         = var.rule_name
      schedule                                     = var.rule_schedule
      target_logically_air_gapped_backup_vault_arn = var.primary_logically_air_gapped_backup_vault_arn
      scan_action = {
        malware_scanner = "GUARDDUTY"
        scan_mode       = "FULL_SCAN"
      }
      lifecycle = {
        delete_after = 35
      }
    }
  ]

  scan_setting = {
    malware_scanner  = "GUARDDUTY"
    resource_types   = ["ALL"]
    scanner_role_arn = var.malware_scanner_role_arn
  }

  # Selection of resources
  selection_name      = var.selection_name
  selection_resources = var.selection_resources

  # Common tags
  tags = var.tags
}
