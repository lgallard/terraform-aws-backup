output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = module.backup.backup_plan_id
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = module.backup.backup_plan_arn
}

output "backup_topic_arn" {
  description = "The ARN of the backup topic"
  value       = aws_sns_topic.backup_notifications.arn
}