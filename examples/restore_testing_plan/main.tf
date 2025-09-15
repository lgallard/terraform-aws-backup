#
# AWS Backup Restore Testing Plan Example
#
# This example demonstrates how to configure AWS Backup restore testing
# to automatically validate backup recovery points on a schedule.
#

# Random suffix for unique resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Example EC2 instance to backup and test restoration
resource "aws_instance" "example" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  tags = {
    Name        = "backup-restore-test-${random_string.suffix.result}"
    Environment = "test"
    BackupPlan  = "daily"
  }

  # Ensure instance is running before backup
  user_data = <<-EOF
    #!/bin/bash
    echo "Test instance for backup restoration validation" > /tmp/test-file.txt
    date >> /tmp/test-file.txt
  EOF
}

# Security group for test instance
resource "aws_security_group" "example" {
  name_prefix = "backup-restore-test-${random_string.suffix.result}"
  vpc_id      = data.aws_vpc.default.id

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backup-restore-test-sg-${random_string.suffix.result}"
  }
}

# AWS Backup configuration with restore testing
module "aws_backup" {
  source = "../.."

  # Enable backup
  enabled    = true
  vault_name = "backup-restore-testing-vault-${random_string.suffix.result}"

  # Backup plan configuration
  plans = {
    daily_backup = {
      name = "daily-backup-plan-${random_string.suffix.result}"
      rules = [
        {
          rule_name         = "daily_backups"
          target_vault_name = "backup-restore-testing-vault-${random_string.suffix.result}"
          schedule          = "cron(0 2 ? * * *)" # Daily at 2 AM UTC
          start_window      = 60                  # 1 hour
          completion_window = 300                 # 5 hours
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 90
          }
          enable_continuous_backup = false
          recovery_point_tags = {
            Environment = "test"
            Purpose     = "restore-testing"
          }
        }
      ]
      selections = [
        {
          name      = "ec2-selection-${random_string.suffix.result}"
          resources = [aws_instance.example.arn]
        }
      ]
    }
  }

  # Restore testing plans configuration
  restore_testing_plans = {
    weekly_restore_test = {
      name                         = "weekly-restore-test-${random_string.suffix.result}"
      schedule_expression          = "cron(0 6 ? * SUN *)" # Weekly on Sundays at 6 AM UTC
      schedule_expression_timezone = "UTC"
      start_window_hours           = 2 # 2 hour window to start testing

      recovery_point_selection = {
        algorithm             = "LATEST_WITHIN_WINDOW"
        include_vaults        = ["*"] # Include all vaults
        recovery_point_types  = ["SNAPSHOT"]
        selection_window_days = 7 # Test recovery points from last 7 days
      }
    }
  }

  # Restore testing selections configuration
  restore_testing_selections = {
    ec2_restore_selection = {
      name                      = "ec2-restore-selection-${random_string.suffix.result}"
      restore_testing_plan_name = "weekly_restore_test"
      protected_resource_type   = "EC2"
      validation_window_hours   = 24 # 24 hours to validate restored resources

      # Test specific EC2 instances with tags
      protected_resource_conditions = {
        string_equals = [
          {
            key   = "aws:ResourceTag/BackupPlan"
            value = "daily"
          }
        ]
      }

      # Override metadata for testing environment
      restore_metadata_overrides = {
        "InstanceType" = "t3.nano" # Use smaller instance for testing
      }
    }
  }

  tags = {
    Environment   = "test"
    Project       = "restore-testing-example"
    CreatedBy     = "terraform"
    ExampleName   = "restore_testing_plan"
    Documentation = "https://github.com/lgallard/terraform-aws-backup/tree/master/examples/restore_testing_plan"
  }
}

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}