terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.11.0" # Required for aws_backup_logically_air_gapped_vault
    }
  }
}
