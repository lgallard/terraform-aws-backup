# AWS Organizations Backup Policy Example

This example demonstrates how to implement AWS Organizations backup policies to manage backups across your entire organization.

## Overview

AWS Organizations backup policies allow you to:
- Centrally manage backup policies across your organization
- Enforce backup compliance standards
- Implement consistent backup strategies
- Manage backup settings across multiple accounts and regions

## Features

1. **Centralized Policy Management**
   - Define backup policies at the organization level
   - Apply policies to organizational units (OUs) or specific accounts
   - Enforce consistent backup standards

2. **Tiered Backup Strategies**
   - Different policies for critical and standard systems
   - Customized retention periods
   - Varied backup frequencies
   - Resource-specific settings

3. **Cross-Region Disaster Recovery**
   - Automatic cross-region backup copies
   - Geographic redundancy
   - Regional compliance support

4. **Resource Selection**
   - Tag-based selection
   - Resource type filtering
   - Conditional selections
   - Exclusion patterns

## Prerequisites

1. **AWS Organizations Setup**
   - Organizations must be enabled
   - Service control policies (SCPs) must be enabled
   - Backup policies must be enabled
   ```bash
   aws organizations enable-aws-service-access --service-principal=backup.amazonaws.com
   ```

2. **IAM Permissions**
   - Management account access
   - Organizations policy management permissions
   - Backup policy permissions
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "organizations:CreatePolicy",
           "organizations:UpdatePolicy",
           "organizations:AttachPolicy",
           "organizations:DetachPolicy"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

## Usage

1. Configure variables in `terraform.tfvars`:
```hcl
management_account_id = "123456789012"
organization_root_id  = "r-abcd"
```

2. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

## Policy Structure

The backup policy structure follows AWS best practices:

1. **Critical Systems**
   - Daily backups
   - 365-day retention
   - Cross-region copies
   - Continuous backup enabled
   - Cold storage transition

2. **Standard Systems**
   - Daily backups
   - 90-day retention
   - Standard backup settings

## Resource Selection

Resources can be selected using:
1. **Direct ARN Patterns**
   ```hcl
   resources = ["arn:aws:rds:*:*:db:*"]
   ```

2. **Tag-Based Selection**
   ```hcl
   tags = {
     Backup = "critical"
   }
   ```

3. **Conditional Selection**
   ```hcl
   conditions = {
     StringEquals = [{
       key   = "Environment"
       value = "Production"
     }]
   }
   ```

## Important Notes

1. **Cost Management**
   - Monitor backup storage costs
   - Review retention periods
   - Optimize selection criteria
   - Consider cross-region copy costs

2. **Compliance**
   - Document policy decisions
   - Regular policy reviews
   - Audit backup compliance
   - Test restore procedures

3. **Operational Considerations**
   - Monitor backup success rates
   - Review backup reports
   - Test restores regularly
   - Update policies as needed
