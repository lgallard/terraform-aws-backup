# AWS Backup
module "aws_backup_example" {
  source = "../.."

  # Vault
  vault_name = "vault-5"

  # Vault lock configuration
  min_retention_days = 7
  max_retention_days = 90

  # Plan
  plan_name = "backup-plan-with-report"

  # Rules
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      }
      copy_actions = []
      recovery_point_tags = {
        Environment = "prod"
      }
    }
  ]

  # Selection
  selections = [
    {
      name = "selection-1"
      selection_tags = [
        {
          type  = "STRINGEQUALS"
          key   = "Environment"
          value = "prod"
        }
      ]
    }
  ]

  # Reports configuration
  reports = [
    {
      name            = "backup_report_plan_1"
      description     = "Daily backup report"
      report_template = "BACKUP_JOB_REPORT"
      s3_bucket_name  = "my-backup-reports"
      formats         = ["CSV", "JSON"]
      accounts        = []
      regions         = []
      framework_arns  = []
    }
  ]

  tags = {
    Owner       = "backup team"
    Environment = "prod"
    Terraform   = true
  }
}

# Configure AWS Provider for S3 bucket in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  providers = {
    aws = aws.us_east_1
  }

  bucket        = "my-backup-reports"
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["reports.backup.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }
}
