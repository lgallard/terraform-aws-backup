terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.11.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "backup" {
  source = "../../../../"

  # Vault configuration - Air Gapped
  vault_name         = var.vault_name
  vault_type         = var.vault_type
  min_retention_days = var.min_retention_days
  max_retention_days = var.max_retention_days

  # Plan configuration
  plan_name = var.plan_name

  # Rule configuration
  rule_name     = "test-rule"
  rule_schedule = "cron(0 2 ? * * *)" # Daily at 2 AM

  # Selection of resources for testing
  selection_name = var.selection_name
  selection_resources = [
    "arn:aws:ec2:*:*:volume/*",
    "arn:aws:dynamodb:*:*:table/*"
  ]

  # Tags for testing
  tags = {
    Environment = "test"
    Purpose     = "terratest"
    VaultType   = var.vault_type
  }
}
