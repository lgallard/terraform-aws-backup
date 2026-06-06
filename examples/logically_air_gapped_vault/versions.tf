terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      # v1.9.0 includes logically air-gapped vault KMS support and the backup
      # plan LAG/malware scanning arguments used by this example.
      source  = "hashicorp/aws"
      version = ">= 6.47.0" # Required for logically air-gapped vault customer-managed KMS key support
    }
  }
}
