# Terraform and provider version constraints

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Primary AWS provider
provider "aws" {
  # Configure your AWS credentials and region
  # region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Module    = "terraform-aws-backup"
      Example   = "secure-backup-configuration"
    }
  }
}

# Cross-region AWS provider for disaster recovery
provider "aws" {
  alias  = "cross_region"
  region = var.cross_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Module    = "terraform-aws-backup"
      Example   = "secure-backup-configuration"
      Type      = "cross-region"
    }
  }
}