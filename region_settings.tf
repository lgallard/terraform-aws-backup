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

resource "aws_backup_region_settings" "this" {
  count = var.enable_region_settings && var.region_settings != null ? 1 : 0

  resource_type_opt_in_preference     = var.region_settings.resource_type_opt_in_preference
  resource_type_management_preference = var.region_settings.resource_type_management_preference
}
