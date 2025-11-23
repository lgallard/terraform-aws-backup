# Region Settings Example
# This example demonstrates how to configure AWS Backup region settings
# to control which AWS services are enabled for backup operations.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Configure region settings to enable specific AWS services for backup
module "region_settings" {
  source = "../.."

  # Enable region settings management
  enable_region_settings = true

  # Configure which services are enabled for backup in this region
  region_settings = {
    # Enable backup for common AWS services
    resource_type_opt_in_preference = {
      "Aurora"                 = true  # Aurora databases
      "DynamoDB"               = true  # DynamoDB tables
      "EBS"                    = true  # EBS volumes
      "EC2"                    = true  # EC2 instances
      "EFS"                    = true  # EFS file systems
      "RDS"                    = true  # RDS databases
      "S3"                     = true  # S3 buckets
      "FSx"                    = false # FSx file systems (disabled for this example)
      "Neptune"                = false # Neptune databases (disabled for this example)
      "Storage Gateway"        = false # Storage Gateway volumes (disabled for this example)
      "DocumentDB"             = false # DocumentDB clusters (disabled for this example)
      "CloudFormation"         = false # CloudFormation stacks (disabled for this example)
      "SAP HANA on Amazon EC2" = false # SAP HANA (disabled for this example)
      "VirtualMachine"         = false # VMware VMs (disabled for this example)
      "DSQL"                   = false # DSQL databases (disabled for this example)
      "Redshift"               = false # Redshift clusters (disabled for this example)
      "Redshift Serverless"    = false # Redshift Serverless (disabled for this example)
    }

    # Optional: Configure resource type management preferences
    # This enables advanced management features for specific services
    resource_type_management_preference = {
      "DynamoDB" = true # Enable DynamoDB advanced backup management
      "EFS"      = true # Enable EFS advanced backup management
    }
  }

  tags = var.tags
}
