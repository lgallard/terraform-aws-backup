output "test_vpc_id" {
  description = "ID of the test VPC"
  value       = aws_vpc.test_vpc.id
}

output "test_subnet_id" {
  description = "ID of the test subnet"
  value       = aws_subnet.test_subnet.id
}

output "test_instance_id" {
  description = "ID of the test EC2 instance"
  value       = aws_instance.test_instance.id
}

output "test_instance_arn" {
  description = "ARN of the test EC2 instance"
  value       = aws_instance.test_instance.arn
}

output "test_volume_id" {
  description = "ID of the test EBS volume"
  value       = aws_ebs_volume.test_volume.id
}

output "test_volume_arn" {
  description = "ARN of the test EBS volume"
  value       = aws_ebs_volume.test_volume.arn
}

output "test_dynamodb_table_name" {
  description = "Name of the test DynamoDB table"
  value       = aws_dynamodb_table.test_table.name
}

output "test_dynamodb_table_arn" {
  description = "ARN of the test DynamoDB table"
  value       = aws_dynamodb_table.test_table.arn
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = module.backup.backup_plan_id
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = module.backup.backup_plan_arn
}

output "backup_vault_id" {
  description = "ID of the backup vault"
  value       = module.backup.backup_vault_id
}

output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = module.backup.backup_vault_arn
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = module.backup.backup_role_arn
}

output "test_resources_for_backup" {
  description = "List of test resources that should be backed up"
  value = {
    ec2_instance    = aws_instance.test_instance.arn
    ebs_volume     = aws_ebs_volume.test_volume.arn
    dynamodb_table = aws_dynamodb_table.test_table.arn
  }
}

output "test_data_validation_info" {
  description = "Information for validating test data after restoration"
  value = {
    test_data_files = [
      "/opt/test-data/test-file-1.txt",
      "/opt/test-data/test-file-2.txt",
      "/opt/test-data/instance-metadata.txt",
      "/opt/test-data/test-data.json"
    ]
    ebs_volume_files = [
      "/mnt/test-data/backup-test/ebs-test-file.txt",
      "/mnt/test-data/backup-test/mount-test.txt"
    ]
    validation_logs = [
      "/var/log/test-data-init.log",
      "/var/log/test-data-validation.log"
    ]
    dynamodb_test_item = {
      table_name = aws_dynamodb_table.test_table.name
      key        = "test-item-1"
    }
  }
}