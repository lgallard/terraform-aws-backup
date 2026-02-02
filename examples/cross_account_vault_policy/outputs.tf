# Outputs for Cross-Account Backup Vault Policy Example

output "vault_arn" {
  description = "ARN of the backup vault"
  value       = module.aws_backup_cross_account.vault_arn
}

output "vault_name" {
  description = "Name of the backup vault"
  value       = module.aws_backup_cross_account.vault_id
}

output "vault_policy_attached" {
  description = "Whether a vault access policy is attached"
  value       = module.aws_backup_cross_account.vault_policy_attached
}

output "vault_policy_details" {
  description = "Vault policy configuration details"
  value       = module.aws_backup_cross_account.vault_policy_details
}

output "kms_key_id" {
  description = "ID of the KMS key used for vault encryption"
  value       = aws_kms_key.backup_vault_key.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for vault encryption"
  value       = aws_kms_key.backup_vault_key.arn
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = module.aws_backup_cross_account.plan_arn
}

output "backup_plan_version" {
  description = "Version of the backup plan"
  value       = module.aws_backup_cross_account.plan_version
}

# Security and management information
output "cross_account_setup_summary" {
  description = "Summary of cross-account backup configuration"
  value = {
    destination_account = data.aws_caller_identity.current.account_id
    destination_region  = data.aws_region.current.name
    vault_name          = module.aws_backup_cross_account.vault_id
    vault_arn           = module.aws_backup_cross_account.vault_arn

    source_accounts = {
      allowed_account_ids = var.source_account_ids
      allowed_regions     = var.allowed_source_regions
    }

    compliance_features = {
      vault_lock_enabled     = var.enable_vault_lock
      min_retention_days     = var.min_retention_days
      max_retention_days     = var.max_retention_days
      kms_encryption_enabled = true
      audit_access_enabled   = true
    }

    policy_configuration = {
      vault_policy_attached = module.aws_backup_cross_account.vault_policy_attached
      policy_principals     = var.source_account_ids
      audit_role_arn        = var.audit_role_arn
    }
  }
}

# Instructions for source accounts
output "source_account_instructions" {
  description = "Instructions for configuring source accounts"
  value = {
    description = "Configuration steps for source accounts to copy backups to this destination vault"

    step_1_iam_policy = {
      description = "Create IAM policy in source accounts with these permissions"
      policy_document = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "AllowBackupCopyToDestination"
            Effect = "Allow"
            Action = [
              "backup:CopyIntoBackupVault",
              "backup:DescribeBackupVault"
            ]
            Resource = [
              module.aws_backup_cross_account.vault_arn,
              "arn:aws:backup:*:${data.aws_caller_identity.current.account_id}:backup-vault:*"
            ]
          },
          {
            Sid    = "AllowKMSAccess"
            Effect = "Allow"
            Action = [
              "kms:Decrypt",
              "kms:GenerateDataKey",
              "kms:CreateGrant"
            ]
            Resource = aws_kms_key.backup_vault_key.arn
            Condition = {
              StringEquals = {
                "kms:ViaService" = "backup.${data.aws_region.current.name}.amazonaws.com"
              }
            }
          }
        ]
      })
    }

    step_2_backup_plan = {
      description = "Configure backup plans in source accounts with copy actions"
      copy_action_example = {
        destination_vault_arn = module.aws_backup_cross_account.vault_arn
        lifecycle = {
          cold_storage_after = var.cold_storage_after_days
          delete_after       = var.delete_after_days
        }
      }
    }

    step_3_testing = {
      description = "Test cross-account backup copy"
      test_commands = [
        "# Create a test backup in source account",
        "aws backup start-backup-job --backup-vault-name source-vault --resource-arn YOUR_RESOURCE_ARN --iam-role-arn YOUR_BACKUP_ROLE_ARN",
        "",
        "# Verify backup appears in destination vault",
        "aws backup list-recovery-points-by-backup-vault --backup-vault-name ${module.aws_backup_cross_account.vault_id}"
      ]
    }
  }
}

# Management and monitoring information
output "management_information" {
  description = "Management commands and monitoring setup"
  value = {
    aws_cli_commands = {
      describe_vault       = "aws backup describe-backup-vault --backup-vault-name ${module.aws_backup_cross_account.vault_id}"
      get_vault_policy     = "aws backup get-backup-vault-access-policy --backup-vault-name ${module.aws_backup_cross_account.vault_id}"
      list_recovery_points = "aws backup list-recovery-points-by-backup-vault --backup-vault-name ${module.aws_backup_cross_account.vault_id}"
      describe_kms_key     = "aws kms describe-key --key-id ${aws_kms_key.backup_vault_key.key_id}"
    }

    console_urls = {
      backup_vault = "https://console.aws.amazon.com/backup/home?region=${data.aws_region.current.name}#/backupvaults/details/${module.aws_backup_cross_account.vault_id}"
      backup_plan  = "https://console.aws.amazon.com/backup/home?region=${data.aws_region.current.name}#/plans"
      kms_key      = "https://console.aws.amazon.com/kms/home?region=${data.aws_region.current.name}#/kms/keys/${aws_kms_key.backup_vault_key.key_id}"
    }

    monitoring = {
      cloudwatch_metrics = [
        "AWS/Backup NumberOfBackupJobsCreated",
        "AWS/Backup NumberOfBackupJobsCompleted",
        "AWS/Backup NumberOfBackupJobsFailed"
      ]
      cloudtrail_events = [
        "CopyIntoBackupVault",
        "CreateBackupVault",
        "PutBackupVaultAccessPolicy"
      ]
    }
  }
}

# Security considerations
output "security_notes" {
  description = "Important security considerations for cross-account backup setup"
  value = {
    kms_encryption = {
      status   = "Enabled with customer-managed key"
      key_id   = aws_kms_key.backup_vault_key.key_id
      key_arn  = aws_kms_key.backup_vault_key.arn
      rotation = var.enable_kms_key_rotation ? "Enabled" : "Disabled"
      note     = "Source accounts need kms:Decrypt and kms:GenerateDataKey permissions"
    }

    vault_lock = {
      status          = var.enable_vault_lock ? "Enabled" : "Disabled"
      mode            = var.lock_changeable_for_days != null ? "Compliance (${var.lock_changeable_for_days} day grace period)" : "Governance"
      min_retention   = var.min_retention_days
      max_retention   = var.max_retention_days
      immutable_after = var.lock_changeable_for_days != null ? "${var.lock_changeable_for_days} days" : "Never (governance mode)"
    }

    access_control = {
      vault_policy                 = "Cross-account access restricted to specified accounts and regions"
      audit_access                 = "Audit role can describe vault and list recovery points"
      source_account_ids           = var.source_account_ids
      allowed_regions              = var.allowed_source_regions
      principle_of_least_privilege = "Policy follows least privilege - only necessary permissions granted"
    }

    recommendations = [
      "Review source account permissions regularly",
      "Monitor CloudTrail for unusual cross-account backup activity",
      "Set up CloudWatch alarms for backup job failures",
      "Use AWS Config to monitor vault policy changes",
      "Implement backup job notifications via SNS",
      "Test restore procedures regularly from both source and destination accounts"
    ]
  }
}
