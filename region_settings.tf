#
# AWS Backup Region Settings
#
# Manages AWS Backup region-level settings for resource type opt-in preferences
# and management. This allows you to control which AWS services are enabled
# for backup operations at the region level.
#
# Note: This is a region-scoped resource. If you need to configure multiple
# regions, you'll need to use provider aliases or separate configurations.
#

#
# Data source to detect current AWS region
#
data "aws_region" "current" {
  count = var.enable_region_settings ? 1 : 0
}

#
# Region Settings Resource with Optional Validation
#
resource "aws_backup_region_settings" "this" {
  count = var.enable_region_settings && var.region_settings != null ? 1 : 0

  resource_type_opt_in_preference     = var.region_settings.resource_type_opt_in_preference
  resource_type_management_preference = var.region_settings.resource_type_management_preference

  lifecycle {
    # Optional strict region validation (opt-in feature)
    precondition {
      condition     = !var.enable_strict_region_validation || var.expected_region == null || try(data.aws_region.current[0].id, "") == var.expected_region
      error_message = "Region mismatch detected: Provider is configured for '${try(data.aws_region.current[0].id, "unknown")}' but expected_region is set to '${var.expected_region}'. This could lead to compliance violations. To bypass this check, set enable_strict_region_validation = false."
    }
  }
}
