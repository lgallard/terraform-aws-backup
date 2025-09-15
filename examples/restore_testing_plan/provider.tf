provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "terraform-aws-backup-restore-testing"
      Example   = "restore_testing_plan"
      Terraform = "true"
    }
  }
}
