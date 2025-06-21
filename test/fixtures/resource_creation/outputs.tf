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
  value       = module.aws_backup.vault_id
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = module.aws_backup.plan_id
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = module.aws_backup.plan_arn
}