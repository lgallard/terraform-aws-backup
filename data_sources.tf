#
# AWS Backup Data Sources
#
# Provides data sources for querying existing AWS Backup resources.
# These data sources allow you to reference backup configurations managed
# outside of this module or query information about existing backup selections.
#

# Note: This is an optional data source configuration.
# To use these data sources, configure them in your calling module.
# The module itself doesn't automatically create data source lookups,
# but this file provides examples and documentation for how to use them.

# Example: Query an existing backup selection
# Uncomment and configure to use:
#
# data "aws_backup_selection" "example" {
#   plan_id      = "your-plan-id"
#   selection_id = "your-selection-id"
# }
#
# Output available attributes:
# - name: Display name of the selection
# - iam_role_arn: IAM role ARN used for backup operations
# - resources: Array of resource ARNs or patterns

# For module users: To query backup selections, use the data source in your
# calling module with the plan IDs from this module's outputs:
#
# data "aws_backup_selection" "my_selection" {
#   plan_id      = module.backup.plan_id
#   selection_id = "selection-id-from-aws"
# }
