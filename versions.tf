terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  # Configuration options
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = terraform.workspace
    }
  }
}
