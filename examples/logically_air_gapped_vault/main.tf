#
# Simple Backup plan with Logically Air Gapped Vault
#

provider "aws" {
  region = var.aws_region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

# Simple plan
module "aws_backup_plan" {
  source = "../../"

  # Vault configuration - Air Gapped
  vault_name         = var.vault_name
  vault_type         = "logically_air_gapped"
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days

  # Plan configuration
  plan_name = var.plan_name

  # Rule configuration
  rule_name     = var.rule_name
  rule_schedule = var.rule_schedule

  # Selection of resources
  selection_name      = var.selection_name
  selection_resources = var.selection_resources

  # Common tags
  tags = var.tags
}