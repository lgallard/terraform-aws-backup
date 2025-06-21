# Test DynamoDB table for backup job testing
resource "aws_dynamodb_table" "test_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = "test"
    Purpose     = "backup-job-testing"
    Terraform   = "true"
  }
}

# Simple backup vault for on-demand backup testing
resource "aws_backup_vault" "test_vault" {
  name        = var.vault_name
  kms_key_arn = aws_kms_key.backup_key.arn

  tags = {
    Environment = "test"
    Purpose     = "backup-job-testing"
    Terraform   = "true"
  }
}

# KMS key for backup vault encryption
resource "aws_kms_key" "backup_key" {
  description             = "KMS key for backup vault encryption"
  deletion_window_in_days = 7

  tags = {
    Environment = "test"
    Purpose     = "backup-job-testing"
    Terraform   = "true"
  }
}

# IAM role for AWS Backup service
resource "aws_iam_role" "backup_role" {
  name = "${var.vault_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "test"
    Purpose     = "backup-job-testing"
    Terraform   = "true"
  }
}

# Attach AWS managed policy for DynamoDB backups
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}