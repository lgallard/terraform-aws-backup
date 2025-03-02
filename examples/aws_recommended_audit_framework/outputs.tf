output "framework_arn" {
  description = "The ARN of the backup framework"
  value       = module.aws_backup_example.framework_arn
}

output "framework_id" {
  description = "The ID of the backup framework"
  value       = module.aws_backup_example.framework_id
}

output "framework_status" {
  description = "The status of the backup framework"
  value       = module.aws_backup_example.framework_status
}
