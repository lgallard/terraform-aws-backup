# Windows VSS Backup Example
# This example demonstrates the Windows VSS backup functionality
# and validation requirements for EC2 instances

module "aws_backup_windows_vss" {
  source = "../.."

  # Basic configuration
  vault_name = "windows_vss_backup_vault"
  plan_name  = "windows_vss_backup_plan"

  # Enable Windows VSS backup (Windows Volume Shadow Copy Service)
  windows_vss_backup = true

  # Add a simple rule
  rule_name         = "daily_backup"
  rule_schedule     = "cron(0 12 * * ? *)"
  rule_start_window = 60

  # OPTION 1: Working configuration with EC2 instances
  # Windows VSS backup requires at least one EC2 instance in the selection
  selection_name = "windows_ec2_selection"
  selection_resources = [
    # Include an EC2 instance to satisfy the validation
    "arn:aws:ec2:us-west-2:123456789012:instance/i-1234567890abcdef0",
    
    # You can also include other resources
    "arn:aws:dynamodb:us-west-2:123456789012:table/my-table"
  ]

  # OPTION 2: Error case - uncomment to test validation error
  # Comment out the above selection_resources and uncomment these lines
  /*
  selection_name = "windows_ec2_selection"
  selection_resources = [
    # No EC2 instances here - will trigger the validation error
    "arn:aws:dynamodb:us-west-2:123456789012:table/my-table"
  ]
  */

  # Additional example with tag-based selection
  # This will select all EC2 instances with the specified tag
  selections = [
    {
      name = "tag_based_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Backup"
        value = "windows-vss"
      }
    }
  ]

  tags = {
    Environment = "test"
    Purpose     = "Windows VSS Backup Example"
  }
} 