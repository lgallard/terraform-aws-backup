<!-- BEGIN_TF_DOCS -->
# AWS Backup Plan with Reports Example

This example demonstrates how to create an AWS Backup plan with reporting capabilities. It includes:

- A backup vault with retention settings
- A backup plan with daily backups
- Resource selection using tags
- Backup reports configuration with S3 bucket integration

## Features

- **Backup Reports**: Generates daily reports in both CSV and JSON formats
- **S3 Integration**: Automatically stores reports in a dedicated S3 bucket
- **Tag-based Selection**: Selects resources for backup based on tags
- **Retention Management**: Configures backup retention periods

## Report Configuration Details

The example configures AWS Backup reports with:
- Report template: BACKUP_JOB_REPORT
- Multiple output formats (CSV and JSON)
- Dedicated S3 bucket with appropriate permissions
- Service-linked role integration

## Usage

```hcl
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
      copy_actions        = []
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
      name              = "backup_report_plan_1"
      description       = "Daily backup report"
      report_template   = "BACKUP_JOB_REPORT"
      s3_bucket_name    = "my-backup-reports"
      formats           = ["CSV", "JSON"]
      accounts         = []
      regions          = []
      framework_arns   = []
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
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.26 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.89.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_backup_example"></a> [aws\_backup\_example](#module\_aws\_backup\_example) | ../.. | n/a |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.6.0 |

## Resources

| Name | Type |
|------|------|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment configuration map. Used to define environment-specific parameters like tags, resource names, and other settings | `map(any)` | <pre>{<br/>  "Environment": "prod",<br/>  "Owner": "devops",<br/>  "Terraform": true<br/>}</pre> | no |


<!-- END_TF_DOCS -->

## Notes

1. The AWS Backup service automatically creates a service-linked role for reports
2. Reports are generated on a daily basis
3. The S3 bucket must be created before configuring the report plan
4. Make sure the bucket name is globally unique
5. The S3 bucket is specifically created in us-east-1 region
6. The bucket policy automatically grants necessary permissions to AWS Backup Reports service
<!-- END_TF_DOCS -->
