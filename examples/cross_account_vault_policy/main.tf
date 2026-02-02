# Cross-Account Backup Vault Policy Example
# This example demonstrates how to configure a backup vault with access policies
# for cross-account backup scenarios

# Local data for constructing the vault policy
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cross_account_vault_policy" {
  # Allow cross-account backup copy operations
  statement {
    sid    = "AllowCrossAccountBackupCopy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [for id in var.source_account_ids : "arn:aws:iam::${id}:root"]
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = ["arn:aws:backup:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:backup-vault:${var.vault_name_prefix}-*"]

    condition {
      test     = "StringEquals"
      variable = "backup:CopySourceRegion"
      values   = var.allowed_source_regions
    }

    condition {
      test     = "Null"
      variable = "backup:CopySourceRegion"
      values   = ["false"]
    }
  }

  # Allow organization-level access for audit and compliance
  statement {
    sid    = "AllowOrganizationAuditAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.audit_role_arn]
    }

    actions = [
      "backup:DescribeBackupVault",
      "backup:ListRecoveryPointsByBackupVault"
    ]

    resources = ["arn:aws:backup:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:backup-vault:${var.vault_name_prefix}-*"]
  }
}

# AWS Backup configuration with vault policy
module "aws_backup_cross_account" {
  source = "../.."

  # Vault configuration
  vault_name        = "${var.vault_name_prefix}-${random_id.vault_suffix.hex}"
  vault_kms_key_arn = aws_kms_key.backup_vault_key.arn

  # Vault access policy for cross-account scenarios
  vault_policy = data.aws_iam_policy_document.cross_account_vault_policy.json

  # Vault lock for compliance (optional)
  locked              = true
  min_retention_days  = 30
  max_retention_days  = 365
  changeable_for_days = 7 # Governance mode for 7 days, then compliance mode

  # Basic backup plan for the destination vault
  plan_name = "cross-account-dr-plan"

  rules = [
    {
      name              = "daily-backup"
      schedule          = "cron(0 2 * * ? *)" # 2 AM daily
      start_window      = 480                 # 8 hours
      completion_window = 720                 # 12 hours
      lifecycle = {
        cold_storage_after = var.cold_storage_after_days
        delete_after       = var.delete_after_days
      }
      recovery_point_tags = {
        BackupType = "CrossAccountDR"
        Compliance = "Required"
      }
    }
  ]

  # Selection for resources to backup (can be empty for destination-only vault)
  selections = []

  tags = {
    Purpose     = "CrossAccountBackup"
    Environment = "production"
    Compliance  = "SOX"
    CostCenter  = "IT-DR"
  }
}

# KMS key for backup vault encryption
resource "aws_kms_key" "backup_vault_key" {
  description             = "KMS key for cross-account backup vault"
  deletion_window_in_days = 7
  enable_key_rotation     = var.enable_kms_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Backup Service"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Cross Account Access for Backup Copy"
        Effect = "Allow"
        Principal = {
          AWS = [for id in var.source_account_ids : "arn:aws:iam::${id}:root"]
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "backup.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "backup-vault-key"
    Purpose     = "CrossAccountBackup"
    Environment = "production"
  }
}

resource "aws_kms_alias" "backup_vault_key_alias" {
  name          = "alias/backup-vault-cross-account"
  target_key_id = aws_kms_key.backup_vault_key.key_id
}

# Random suffix for unique vault name
resource "random_id" "vault_suffix" {
  byte_length = 4
}

# Data sources for region information
data "aws_region" "current" {}
