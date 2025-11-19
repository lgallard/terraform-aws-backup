# Version compatibility requirements
# Terraform: >= 1.3.0 (tested on 1.3.0 - 1.11.4+)
# OpenTofu: >= 1.6.0 (tested on 1.6.0 - 1.9.3+)
#
# Note: Terraform 1.0-1.2 and OpenTofu < 1.6 may experience "argument must not be null" errors
# when using vault lock features due to null value handling in boolean expressions.
# This module includes fixes in main.tf (retention_days_cross_valid) to ensure compatibility
# with newer versions while maintaining correct validation logic.

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}
