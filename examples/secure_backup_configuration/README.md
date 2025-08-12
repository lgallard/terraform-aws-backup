# Secure Backup Configuration Example

This example demonstrates security best practices for AWS Backup configuration, including:

- Customer-managed KMS encryption
- Least-privilege IAM roles
- Vault lock configuration for compliance
- Cross-region backup with proper security controls
- Comprehensive monitoring and alerting

## Security Features

### 1. Encryption at Rest
- Uses customer-managed KMS keys
- Separate keys for primary and cross-region backups
- Proper key rotation policies

### 2. Access Control
- Least-privilege IAM roles
- Service-specific permissions
- Resource-based policies

### 3. Compliance
- Vault lock configuration
- Minimum retention periods
- Audit logging

### 4. Monitoring
- CloudWatch alarms for failed backups
- SNS notifications for security events
- CloudTrail integration

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0
3. KMS keys created for encryption
4. SNS topic for notifications (optional)

## Usage

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Security Checklist

Before deploying to production, ensure:

- [ ] KMS keys are customer-managed
- [ ] IAM roles follow least-privilege principle
- [ ] Vault lock is enabled for compliance workloads
- [ ] Retention policies meet compliance requirements
- [ ] Cross-region backups use proper key management
- [ ] CloudTrail logging is enabled
- [ ] Monitoring and alerting are configured

## Cost Considerations

This configuration includes:
- KMS key usage charges
- Cross-region backup storage costs
- CloudWatch metrics and alarms
- SNS notification costs

Estimated monthly cost: $50-200 depending on backup frequency and retention.

## Compliance

This configuration supports:
- SOC 2 Type II
- HIPAA
- PCI DSS
- ISO 27001

## Files

- `main.tf` - Main backup configuration
- `kms.tf` - KMS key configuration
- `monitoring.tf` - CloudWatch alarms and monitoring
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `versions.tf` - Provider versions
- `terraform.tfvars.example` - Example variable values
