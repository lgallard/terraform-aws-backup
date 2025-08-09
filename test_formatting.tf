# Test file with intentional formatting issues
# This will test the pre-commit workflow

resource "aws_backup_vault" "test"  {
  name = "test-vault"    
  # Extra trailing whitespace above and missing newline below
  kms_key_arn =  aws_kms_key.backup.arn
}

resource "aws_kms_key" "backup"{description="Test KMS key"
 
  # Inconsistent indentation and spacing
deletion_window_in_days=7}

# Missing final newline