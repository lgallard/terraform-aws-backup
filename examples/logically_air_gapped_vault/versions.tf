terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.47.0" # Required for logically air-gapped vault customer-managed KMS key support
    }
  }
}
