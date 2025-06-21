output "table_name" {
  description = "Name of the created DynamoDB table"
  value       = aws_dynamodb_table.test_table.name
}

output "table_arn" {
  description = "ARN of the created DynamoDB table"
  value       = aws_dynamodb_table.test_table.arn
}

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.test_vault.name
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = aws_iam_role.backup_role.arn
}