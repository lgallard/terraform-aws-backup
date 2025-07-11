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
            "kms:ViaService" = "backup.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  # Security settings
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-backup-key"
    Type = "backup-encryption"
  })
}

# KMS key alias for easier reference
resource "aws_kms_alias" "backup_key" {
  name          = "alias/${var.project_name}-${var.environment}-backup"
  target_key_id = aws_kms_key.backup_key.key_id
}

# Cross-region backup KMS key
resource "aws_kms_key" "cross_region_backup_key" {
  count = var.enable_cross_region_backup ? 1 : 0
  
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
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cross-region-backup-key"
    Type = "cross-region-backup-encryption"
  })
  
  provider = aws.cross_region
}

# Cross-region KMS key alias
resource "aws_kms_alias" "cross_region_backup_key" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  name          = "alias/${var.project_name}-${var.environment}-cross-region-backup"
  target_key_id = aws_kms_key.cross_region_backup_key[0].key_id
  
  provider = aws.cross_region
}

# KMS key for SNS encryption
resource "aws_kms_key" "sns_key" {
  description = "KMS key for ${var.project_name} ${var.environment} SNS encryption"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableSNSAccess"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
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
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "EnableIAMUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sns-key"
    Type = "sns-encryption"
  })
}

# SNS KMS key alias
resource "aws_kms_alias" "sns_key" {
  name          = "alias/${var.project_name}-${var.environment}-sns"
  target_key_id = aws_kms_key.sns_key.key_id
}