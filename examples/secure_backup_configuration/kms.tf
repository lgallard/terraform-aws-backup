# KMS keys for secure backup encryption

# Primary backup vault KMS key
resource "aws_kms_key" "backup_key" {
  description = "KMS key for ${var.project_name} ${var.environment} backup encryption"

  # Security-focused key policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableBackupServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "backup.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "backup.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/backup/*"
          }
        }
      }
    ]
  })

  # Enable automatic key rotation for security
  enable_key_rotation = true

  # Prevent accidental deletion
  deletion_window_in_days = 30

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.environment}-backup-key"
    Purpose     = "backup-encryption"
    KeyType     = "primary"
    Compliance  = "required"
  })
}

# Create alias for easier management
resource "aws_kms_alias" "backup_key" {
  name          = "alias/${var.project_name}-${var.environment}-backup"
  target_key_id = aws_kms_key.backup_key.key_id
}

# Cross-region backup vault KMS key (conditional)
resource "aws_kms_key" "cross_region_backup_key" {
  count = var.enable_cross_region_backup ? 1 : 0

  # Create in the cross-region provider context
  provider = aws.cross_region

  description = "KMS key for ${var.project_name} ${var.environment} cross-region backup encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableBackupServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "backup.${var.cross_region}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "backup.${data.aws_region.current.id}.amazonaws.com",
              "backup.${var.cross_region}.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "AllowCrossRegionBackupAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "backup.${data.aws_region.current.id}.amazonaws.com",
              "backup.${var.cross_region}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = merge(local.common_tags, {
    Name        = "${var.project_name}-${var.environment}-backup-cross-region-key"
    Purpose     = "cross-region-backup-encryption"
    KeyType     = "cross-region"
    Region      = var.cross_region
    Compliance  = "required"
  })
}

# Cross-region KMS alias
resource "aws_kms_alias" "cross_region_backup_key" {
  count = var.enable_cross_region_backup ? 1 : 0

  provider = aws.cross_region

  name          = "alias/${var.project_name}-${var.environment}-backup-cross-region"
  target_key_id = aws_kms_key.cross_region_backup_key[0].key_id
}
