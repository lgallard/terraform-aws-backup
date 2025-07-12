# Contributing to terraform-aws-backup

Thank you for your interest in contributing to the terraform-aws-backup module! This document outlines our coding standards, development workflow, and review process.

## 🚀 Quick Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following our coding standards
4. Run pre-commit hooks: `pre-commit run --all-files`
5. Test your changes with examples
6. Submit a pull request

## 📋 Code Quality Standards

### Terraform Code Style

#### Variable Definitions
- **Descriptive names**: Use clear, descriptive variable names
- **Consistent types**: Always specify variable types explicitly
- **Validation rules**: Add validation for all input variables where applicable
- **Documentation**: Include helpful descriptions with examples

```hcl
# ✅ Good
variable "vault_kms_key_arn" {
  description = "The server-side encryption key that is used to protect your backups"
  type        = string
  default     = null

  validation {
    condition = var.vault_kms_key_arn == null ? true : (
      can(regex("^arn:aws:kms:", var.vault_kms_key_arn)) &&
      !can(regex("alias/aws/", var.vault_kms_key_arn))
    )
    error_message = "The vault_kms_key_arn must be a valid customer-managed KMS key ARN."
  }
}

# ❌ Bad
variable "key" {
  type = string
}
```

#### Resource Organization
- **Logical grouping**: Group related resources together
- **Clear naming**: Use descriptive resource names
- **Conditional creation**: Use locals for complex conditions
- **Documentation**: Comment complex logic

```hcl
# ✅ Good
locals {
  should_create_vault = var.enabled && var.vault_name != null
  should_create_lock = local.should_create_vault && var.locked
}

resource "aws_backup_vault" "ab_vault" {
  count = local.should_create_vault ? 1 : 0
  # ...
}

# ❌ Bad
resource "aws_backup_vault" "ab_vault" {
  count = var.enabled && var.vault_name != null ? 1 : 0
  # ...
}
```

#### Error Messages
- **Contextual information**: Include current values and guidance
- **Clear language**: Use simple, direct language
- **Helpful guidance**: Explain what the user should do

```hcl
# ✅ Good
error_message = "changeable_for_days must be between 3 and 365 days. Current value: ${var.changeable_for_days}. This parameter controls the vault lock compliance period."

# ❌ Bad
error_message = "Invalid value."
```

### Constants and Magic Numbers
- **No magic numbers**: Replace hardcoded values with named constants
- **Configurable defaults**: Make defaults configurable via variables
- **Clear naming**: Use descriptive names for constants

```hcl
# ✅ Good
variable "default_lifecycle_delete_after_days" {
  description = "Default number of days after creation that a recovery point is deleted"
  type        = number
  default     = 90
}

delete_after = try(lifecycle.value.delete_after, var.default_lifecycle_delete_after_days)

# ❌ Bad
delete_after = try(lifecycle.value.delete_after, 90)
```

## 🔒 Security Standards

### Input Validation
- **Validate all inputs**: Use validation blocks for all variables
- **Prevent misuse**: Block common misconfigurations
- **Security-first defaults**: Choose secure defaults

### Sensitive Data
- **No hardcoded secrets**: Never commit secrets or keys
- **Secure defaults**: Use customer-managed keys over AWS-managed
- **Minimal permissions**: Follow principle of least privilege

## 🧪 Testing Requirements

### Before Submitting
1. **Linting**: All linting rules must pass
   ```bash
   terraform fmt -check -recursive
   tflint --config=.tflint.hcl
   ```

2. **Security scanning**: Checkov security checks must pass
   ```bash
   checkov -d . --framework terraform
   ```

3. **Examples**: Test all relevant examples
   ```bash
   cd examples/simple_plan
   terraform init
   terraform plan
   ```

4. **Backwards compatibility**: Verify no breaking changes
   ```bash
   # Before changes
   terraform plan -out=before.plan
   # After changes  
   terraform plan -out=after.plan
   # Compare plans should show identical resources
   ```

## 📝 Code Review Checklist

### For Reviewers

#### ✅ Code Quality
- [ ] Code follows Terraform best practices
- [ ] Variables have proper validation and documentation
- [ ] No magic numbers or hardcoded values
- [ ] Error messages are helpful and contextual
- [ ] Complex logic is simplified and well-commented

#### ✅ Security
- [ ] No secrets or sensitive data in code
- [ ] Input validation prevents common misconfigurations
- [ ] Security scanning (Checkov) passes
- [ ] Uses secure defaults (customer-managed keys, etc.)

#### ✅ Compatibility
- [ ] Changes are backwards compatible
- [ ] All existing examples still work
- [ ] terraform plan produces identical results for existing configurations
- [ ] No breaking changes to variable or output interfaces

#### ✅ Documentation
- [ ] README updated if needed
- [ ] Variable descriptions are clear and helpful
- [ ] Examples demonstrate new features
- [ ] CHANGELOG updated for user-facing changes

#### ✅ Testing
- [ ] All linting checks pass
- [ ] Security scans pass
- [ ] Examples work correctly
- [ ] terraform-docs generates correct documentation

### For Contributors

#### Before Submitting PR
- [ ] Followed coding standards outlined above
- [ ] Added/updated tests for new functionality
- [ ] Updated documentation as needed
- [ ] Ran pre-commit hooks successfully
- [ ] Tested examples work correctly
- [ ] Verified backwards compatibility

#### PR Description Should Include
- [ ] Clear description of changes
- [ ] Reasoning for the changes
- [ ] Any breaking changes (should be rare)
- [ ] Testing performed
- [ ] Screenshots/examples if applicable

## 🔧 Development Environment Setup

### Prerequisites
- Terraform >= 1.0
- Pre-commit hooks
- tflint with AWS ruleset
- Checkov

### Setup
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install tflint AWS ruleset
tflint --init

# Install checkov
pip install checkov
```

### Pre-commit Configuration
Our pre-commit configuration includes:
- Terraform formatting (`terraform fmt`)
- Terraform validation (`terraform validate`)
- Terraform documentation (`terraform-docs`)
- Terraform linting (`tflint`)
- Security scanning (`checkov`)
- Secrets detection (`detect-secrets`)
- Spell checking for documentation
- General file quality checks

## 🎯 Contribution Guidelines

### Types of Contributions
- **Bug fixes**: Always welcome
- **Feature enhancements**: Discuss in issues first
- **Documentation improvements**: Very helpful
- **Example additions**: Great for community

### Breaking Changes
- **Avoid when possible**: Strive for backwards compatibility
- **Major version only**: Breaking changes only in major releases
- **Clear migration path**: Provide migration guide
- **Advance notice**: Discuss in issues before implementing

### Code Organization
- **Maintain standard structure**: Keep standard Terraform file layout
- **Logical grouping**: Group related functionality together
- **Clear separation**: Separate concerns appropriately
- **Consistent patterns**: Follow existing code patterns

## 🏷️ Versioning and Releases

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backwards compatible)
- **PATCH**: Bug fixes

## 🤝 Community

- **Be respectful**: Follow our code of conduct
- **Be collaborative**: Help others learn and contribute
- **Be constructive**: Provide helpful feedback
- **Be patient**: Reviews take time for quality

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Backup Documentation](https://docs.aws.amazon.com/backup/)
- [Module Examples](./examples/)
- [Issue Templates](./.github/ISSUE_TEMPLATE/)

---

Thank you for contributing to terraform-aws-backup! Your contributions help make AWS backup management easier for everyone.