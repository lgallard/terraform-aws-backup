# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.24.x  | :white_check_mark: |
| 0.23.x  | :x:                |
| < 0.23  | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do not** open a public GitHub issue
2. **Do not** disclose the vulnerability publicly until it has been resolved
3. Email the maintainer at [security@example.com] with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will acknowledge your report within 48 hours and provide a timeline for resolution.

## Security Best Practices

### AWS Backup Security Configuration

#### 1. Encryption at Rest

**Always use customer-managed KMS keys for backup encryption:**

```hcl
# ✅ Secure - Using customer-managed KMS key
module "backup" {
  source = "lgallard/backup/aws"
  
  vault_name        = "production-backup-vault"
  vault_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # ... other configuration
}
```

```hcl
# ❌ Insecure - Using AWS managed key
module "backup" {
  source = "lgallard/backup/aws"
  
  vault_name        = "production-backup-vault"
  vault_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:alias/aws/backup"  # Avoid this
  
  # ... other configuration
}
```

#### 2. IAM Roles and Policies

**Follow the principle of least privilege:**

```hcl
# ✅ Secure - Using service-specific IAM role
module "backup" {
  source = "lgallard/backup/aws"
  
  # Let the module create the IAM role with minimal permissions
  # Or provide a custom role with only necessary permissions
  
  # ... other configuration
}
```

```hcl
# ❌ Insecure - Using overly permissive role
module "backup" {
  source = "lgallard/backup/aws"
  
  iam_role_arn = "arn:aws:iam::123456789012:role/AdminRole"  # Avoid this
  
  # ... other configuration
}
```

#### 3. Backup Vault Security

**Configure appropriate retention policies:**

```hcl
# ✅ Secure configuration
module "backup" {
  source = "lgallard/backup/aws"
  
  vault_name         = "production-backup-vault"
  min_retention_days = 30    # Minimum 30 days for compliance
  max_retention_days = 2555  # Maximum 7 years for compliance
  
  # Enable vault lock for compliance
  locked              = true
  changeable_for_days = 3
  
  # ... other configuration
}
```

#### 4. Cross-Region Backup Security

**For cross-region backups, ensure proper key management:**

```hcl
# ✅ Secure cross-region configuration
module "backup" {
  source = "lgallard/backup/aws"
  
  rules = [
    {
      name = "daily-backup"
      schedule = "cron(0 5 ? * * *)"
      
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:dr-vault"
          lifecycle = {
            delete_after = 30
          }
        }
      ]
    }
  ]
  
  # ... other configuration
}
```

### Security Checklist

Before deploying to production, ensure:

- [ ] **Encryption**: Customer-managed KMS keys are used
- [ ] **IAM**: Least-privilege IAM roles are configured
- [ ] **Retention**: Appropriate retention policies are set (min 7 days)
- [ ] **Vault Lock**: Vault lock is enabled for compliance workloads
- [ ] **Cross-Region**: Cross-region backups use proper key management
- [ ] **Monitoring**: CloudTrail logging is enabled for backup operations
- [ ] **Access Control**: Resource-based policies restrict access appropriately
- [ ] **Tagging**: Resources are properly tagged for access control

### Common Security Misconfigurations

#### 1. Weak Naming Conventions

```hcl
# ❌ Avoid these naming patterns
vault_name = "test-vault"     # Suggests temporary use
vault_name = "default-vault"  # Too generic
vault_name = "temp-backup"    # Suggests temporary use
```

```hcl
# ✅ Use descriptive, environment-specific names
vault_name = "production-app-backup-vault"
vault_name = "staging-database-backup-vault"
```

#### 2. Insecure Retention Policies

```hcl
# ❌ Too short retention for compliance
min_retention_days = 1  # Insufficient for most compliance frameworks
```

```hcl
# ✅ Compliance-appropriate retention
min_retention_days = 30   # Meets most compliance requirements
max_retention_days = 2555 # 7 years for long-term compliance
```

#### 3. Overly Permissive IAM Roles

```hcl
# ❌ Avoid these role patterns
iam_role_arn = "arn:aws:iam::123456789012:role/AdminRole"
iam_role_arn = "arn:aws:iam::123456789012:role/PowerUserRole"
iam_role_arn = "arn:aws:iam::123456789012:role/FullAccessRole"
```

### Security Monitoring

#### CloudTrail Events to Monitor

Monitor these AWS Backup-related CloudTrail events:

- `backup:CreateBackupVault`
- `backup:DeleteBackupVault`
- `backup:CreateBackupPlan`
- `backup:DeleteBackupPlan`
- `backup:StartBackupJob`
- `backup:StopBackupJob`
- `backup:StartRestoreJob`
- `kms:Decrypt` (for backup operations)
- `kms:GenerateDataKey` (for backup encryption)

#### Security Metrics

Set up CloudWatch alarms for:

- Failed backup jobs
- Unauthorized access attempts
- Unusual backup patterns
- KMS key usage anomalies

### Compliance Considerations

#### SOC 2 Type II

- Enable vault lock with appropriate retention
- Implement proper access controls
- Maintain audit logs of all backup operations
- Regular security assessments

#### HIPAA

- Use customer-managed KMS keys
- Implement encryption in transit and at rest
- Maintain access logs and audit trails
- Regular risk assessments

#### PCI DSS

- Encrypt all backup data
- Implement strong access controls
- Regular security testing
- Maintain secure configurations

## Security Updates

This project follows semantic versioning for security updates:

- **MAJOR** version for breaking security changes
- **MINOR** version for new security features
- **PATCH** version for security fixes

Subscribe to GitHub releases to stay informed about security updates.

## Vulnerability Disclosure Timeline

1. **Day 0**: Vulnerability reported
2. **Day 1-2**: Acknowledgment and initial assessment
3. **Day 3-7**: Detailed analysis and fix development
4. **Day 8-14**: Testing and validation
5. **Day 15**: Public disclosure and release

## Security Testing

This project includes:

- Static security analysis (Checkov, tfsec)
- Dependency vulnerability scanning
- Infrastructure security testing
- Regular security audits

## Contact

For security-related questions or concerns:

- Email: security@example.com
- GitHub: Create a private security advisory
- GPG Key: [Include if applicable]

## Acknowledgments

We appreciate responsible disclosure of security vulnerabilities. Contributors who report valid security issues will be acknowledged in our security advisories (with permission).