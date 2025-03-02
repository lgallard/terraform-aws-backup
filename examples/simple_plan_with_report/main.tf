module "aws_backup_example" {

  source = "../.."

  # Vault
  vault_name = "vault-1"

  # Plan
  plan_name = "simple-plan-list"

  # One rule using a list of maps
  rules = [
    {
      name                     = "rule-1"
      schedule                 = "cron(0 12 * * ? *)"
      start_window             = 120
      completion_window        = 360
      enable_continuous_backup = true
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      },
      recovery_point_tags = {
        Environment = "production"
      }
    },
  ]

  # One selection using a list of maps
  selections = [
    {
      name      = "selection-1"
      resources = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table"]
    },
  ]

  reports = [
    {
      name            = "report-vault-1"
      formats         = ["CSV"]
      s3_bucket_name  = module.s3_bucket.s3_bucket_id
      s3_key_prefix   = "vault-1/"
      report_template = "BACKUP_JOB_REPORT"
    }
  ]

  tags = {
    Owner       = "devops"
    Environment = "production"
    Terraform   = true
  }

}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket        = "my-backup-reports"
  attach_policy = true
  policy        = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_iam_service_linked_role" "backup_role" {
  aws_service_name = "reports.backup.amazonaws.com"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_service_linked_role.backup_role.arn]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::my-backup-reports/*",
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
