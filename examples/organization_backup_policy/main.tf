module "aws_backup_example" {
  source = "../.."

  # Enable Organization backup policies
  enable_org_policy    = true
  org_policy_name      = "backup-policy"
  org_policy_target_id = var.organization_root_id

  # Plan
  plan_name = "org-backup-plan"

  # Rules using list of maps
  rules = [
    {
      name                     = "critical-systems"
      target_vault_name        = "critical-systems-vault"
      schedule                 = "cron(0 5 ? * * *)" # Daily at 5 AM
      start_window             = 60
      completion_window        = 120
      enable_continuous_backup = true
      lifecycle = {
        delete_after       = 365
        cold_storage_after = 90
      }
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:${var.management_account_id}:backup-vault:dr-vault"
          lifecycle = {
            delete_after = 365
          }
        }
      ]
      recovery_point_tags = {
        Environment = "Production"
        Criticality = "High"
      }
    },
    {
      name              = "standard-systems"
      target_vault_name = "standard-systems-vault"
      schedule          = "cron(0 1 ? * * *)" # Daily at 1 AM
      start_window      = 120
      completion_window = 360
      lifecycle = {
        delete_after = 90
      }
      recovery_point_tags = {
        Environment = "Production"
        Criticality = "Standard"
      }
    }
  ]

  # Selections using list of maps
  selections = [
    {
      name = "critical-databases"
      resources = [
        "arn:aws:rds:*:*:db:*",
        "arn:aws:dynamodb:*:*:table/*"
      ]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Backup"
          value = "critical"
        }
      ]
    },
    {
      name      = "production-volumes"
      resources = ["arn:aws:ec2:*:*:volume/*"]
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "Production"
        }
      ]
    }
  ]

  advanced_backup_settings = {
    ec2 = {
      windows_vss = "enabled"
    }
  }

  backup_regions = [
    "us-west-2",
    "us-east-1"
  ]

  tags = {
    Environment = "production"
    Management  = "organizations"
  }
}
