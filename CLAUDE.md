# Terraform AWS Backup Module - Development Guidelines

## Overview
This document outlines Terraform-specific development guidelines for the terraform-aws-backup module, focusing on best practices for AWS infrastructure as code.

## Module Structure & Organization

### File Organization
- **main.tf** - Primary resource definitions and locals
- **variables.tf** - Input variable definitions with validation
- **outputs.tf** - Output value definitions
- **versions.tf** - Provider version constraints
- **iam.tf** - IAM roles and policies
- **notifications.tf** - SNS and notification configurations
- **organizations.tf** - AWS Organizations backup policies
- **selection.tf** - Resource selection logic
- **reports.tf** - Backup reporting configurations
- **audit_manager.tf** - Audit framework configurations

### Code Organization Principles
- Group related resources logically in separate files
- Use descriptive locals for complex expressions
- Maintain backward compatibility with existing variable names
- Keep validation logic close to variable definitions

## MCP-Powered Validation Workflow

### Development Lifecycle with MCP Integration

**Before Implementation:**
```bash
# Validate resource documentation
Terraform MCP: "Look up aws_backup_vault resource documentation"
Context7: "Get AWS Backup best practices"
```

**During Development:**
```bash
# Validate syntax and arguments
Terraform MCP: "Validate aws_backup_plan arguments"
Terraform MCP: "Check aws_backup_selection resource requirements"
```

**Testing Phase:**
```bash
# Get testing patterns
Context7: "Find Terratest patterns for AWS Backup"
Context7: "Get Go testing best practices"
```

**Security Review:**
```bash
# Validate security configurations
Context7: "AWS Backup encryption best practices"
Terraform MCP: "Look up aws_kms_key for backup vault"
```

## Terraform Best Practices

### Resource Creation Patterns
**Favor `for_each` over `count`** for resource creation:

```hcl
# Preferred: Using for_each
resource "aws_backup_plan" "this" {
  for_each = var.enabled ? var.plans : {}

  name = each.value.name
  # ...
}

# Validate with: Terraform MCP "Check aws_backup_plan for_each patterns"
```

### Variables & Validation
Use validation blocks for critical inputs:

```hcl
variable "vault_name" {
  description = "Name of the backup vault to create"
  type        = string
  default     = null

  validation {
    condition     = var.vault_name == null ? true : can(regex("^[0-9A-Za-z-_]{2,50}$", var.vault_name))
    error_message = "The vault_name must be between 2 and 50 characters, contain only alphanumeric characters, hyphens, and underscores."
  }
}
# Validate naming rules with: Terraform MCP "aws_backup_vault naming constraints"
```

### Locals Organization
Structure locals for clarity and reusability:

```hcl
locals {
  # Resource creation conditions
  should_create_vault = var.enabled && var.vault_name != null
  should_create_lock  = local.should_create_vault && var.locked

  # Data processing
  rules = concat(local.rule, var.rules)

  # Validation helpers
  vault_lock_requirements_met = var.min_retention_days != null && var.max_retention_days != null
}
```

## Testing Requirements

### Test Coverage Guidelines
- **New Features**: Create test files in `test/` directory with corresponding examples
- **Modifications**: Add missing tests for modified functionality
- **Use Terratest**: Integration testing with AWS Backup-specific retry logic
- **Reference Examples**: See `test/` directory for test implementations

### AWS Backup Testing Framework
The testing framework includes retry logic for AWS Backup API limitations. Test structure:

```
test/
├── go.mod                          # Go dependencies
├── helpers.go                      # Backup-specific test helpers
├── integration_test.go             # Main integration tests
└── fixtures/terraform/             # Test configurations
```

**For detailed test examples**: Refer to `test/integration_test.go` and `test/helpers.go`

### Testing Environment Variables
```bash
# Configure retry behavior for backup operations
export TEST_RETRY_MAX_ATTEMPTS=5           # Higher retry count for backup APIs
export TEST_RETRY_INITIAL_DELAY=10s        # Longer initial delay
export TEST_RETRY_MAX_DELAY=300s           # Extended max delay

# Backup-specific test configurations
export AWS_BACKUP_TEST_REGION=us-east-1
export AWS_BACKUP_TEST_VAULT_PREFIX=terratest
```

**MCP Validation**: Use `Context7: "Get Terratest retry patterns for AWS services"`

## Pre-commit Configuration

### Quick Setup
```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# Run manually
pre-commit run --all-files
```

### Required Tools
- Terraform 1.3.0+
- terraform-docs v0.16.0+
- TFLint

### GitHub Actions Integration
The module includes automated pre-commit checks via `.github/workflows/pre-commit.yml`:
- Runs on PRs and master pushes
- Validates formatting, syntax, and documentation
- Caches tools for performance

**Troubleshooting**: Run `terraform fmt -recursive .` and `tflint` locally

## Security Considerations

### Comprehensive Security Pattern
```hcl
# Example: Unified security configuration with multiple validations
variable "security_config" {
  description = "Comprehensive security settings for backup operations"
  type = object({
    vault_kms_key_arn    = string
    enable_vault_lock    = bool
    min_retention_days   = number
    max_retention_days   = number
    allowed_principals   = list(string)
    restricted_actions   = list(string)
  })

  # KMS Key validation
  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/", var.security_config.vault_kms_key_arn))
    error_message = "Invalid KMS key ARN format."
  }

  # Retention validation
  validation {
    condition     = var.security_config.min_retention_days <= var.security_config.max_retention_days
    error_message = "min_retention_days must be <= max_retention_days."
  }

  # Principal validation - no wildcards
  validation {
    condition     = !contains(var.security_config.allowed_principals, "*")
    error_message = "Wildcard principals not allowed for security."
  }
}

# Secure vault implementation
resource "aws_backup_vault" "this" {
  name        = var.vault_name
  kms_key_arn = var.security_config.vault_kms_key_arn

  # Vault lock for compliance
  dynamic "backup_vault_lock_configuration" {
    for_each = var.security_config.enable_vault_lock ? [1] : []
    content {
      min_retention_days = var.security_config.min_retention_days
      max_retention_days = var.security_config.max_retention_days
    }
  }
}

# Validate with: Terraform MCP "aws_backup_vault_lock_configuration requirements"
```

### Security Best Practices
- **Always use KMS encryption** for backup vaults
- **Apply least privilege** IAM policies
- **Enable vault lock** for compliance requirements
- **Restrict cross-account access** appropriately
- **Implement audit frameworks** for tracking

**MCP Validation**: `Context7: "AWS Backup security checklist"`

## AWS Backup Development Patterns

### Unified Pattern Example
```hcl
# Example: Flexible backup configuration supporting multiple scenarios
variable "backup_config" {
  description = "Unified backup configuration"
  type = object({
    # Audit framework settings
    enable_audit     = bool
    audit_controls   = list(string)

    # Organization policy settings
    enable_org_policy = bool
    target_ous        = list(string)

    # VSS settings for Windows
    enable_vss        = bool
    vss_timeout       = number

    # Cost optimization
    enable_tiering    = bool
    cold_storage_days = number
  })
}

# Process configuration based on enabled features
locals {
  audit_enabled = var.backup_config.enable_audit && length(var.backup_config.audit_controls) > 0
  org_enabled   = var.backup_config.enable_org_policy && length(var.backup_config.target_ous) > 0
  vss_enabled   = var.backup_config.enable_vss && var.backup_config.vss_timeout > 0
}

# Validate patterns with: Terraform MCP "aws_backup advanced configurations"
```

For detailed pattern implementations, see:
- **Audit Framework**: `examples/complete_audit_framework/`
- **Organization Policy**: `examples/organization_backup_policy/`
- **VSS Backup**: `examples/simple_plan_windows_vss_backup/`
- **Cost Optimization**: `examples/cost_optimized_backup/`

## Specific Module Patterns

### Multi-Selection Support
```hcl
# Support multiple input formats gracefully
# PERFORMANCE: For >100 selections, use dedicated resources
selection_resources = flatten([
  var.selection_resources,
  [for selection in try(tolist(var.selections), []) : try(selection.resources, [])],
  [for selection in var.backup_selections : try(selection.resources, [])]
])

# Validate with: Terraform MCP "aws_backup_selection performance tips"
```

## Development Workflow

### Pre-commit Requirements
1. Run `terraform fmt` on modified files
2. Execute `terraform validate`
3. Run tests for affected functionality
4. Update documentation for variable changes

### Release Management
- **DO NOT manually update CHANGELOG.md** - use release-please
- Use conventional commit messages (feat:, fix:, chore:)
- Follow semantic versioning principles

## Available Examples

The module includes 16 comprehensive examples demonstrating various backup scenarios:

| Example | Description | Key Features | MCP Validation |
|---------|-------------|--------------|----------------|
| `simple_plan` | Basic backup configuration | Single plan, daily backups | `Terraform MCP: "aws_backup_plan basics"` |
| `multiple_plans` | Multi-plan setup | Different schedules, lifecycles | `Terraform MCP: "aws_backup_plan multiple"` |
| `selection_by_tags` | Tag-based selection | Dynamic resource targeting | `Terraform MCP: "aws_backup_selection tags"` |
| `selection_by_conditions` | Condition-based selection | Complex selection logic | `Terraform MCP: "aws_backup_selection conditions"` |
| `cross_region_backup` | Cross-region replication | DR configuration | `Terraform MCP: "aws_backup cross-region"` |
| `simple_plan_using_lock_configuration` | Vault lock setup | Compliance features | `Terraform MCP: "aws_backup_vault_lock"` |
| `organization_backup_policy` | Org-wide policies | Enterprise governance | `Terraform MCP: "aws_organizations_policy backup"` |
| `complete_audit_framework` | Full audit setup | Compliance tracking | `Terraform MCP: "aws_backup_framework"` |
| `aws_recommended_audit_framework` | AWS best practices | Pre-configured controls | `Context7: "AWS Backup audit controls"` |
| `simple_audit_framework` | Basic audit config | Essential controls | `Terraform MCP: "aws_backup_framework simple"` |
| `simple_plan_windows_vss_backup` | Windows VSS | Application-consistent backups | `Terraform MCP: "aws_backup VSS"` |
| `notifications_only_on_failed_jobs` | Failure notifications | SNS integration | `Terraform MCP: "aws_backup_notifications"` |
| `simple_plan_with_report` | Backup reporting | Compliance reports | `Terraform MCP: "aws_backup_report_plan"` |
| `cost_optimized_backup` | Cost optimization | Tiering strategies | `Context7: "AWS Backup cost optimization"` |
| `secure_backup_configuration` | Security hardening | KMS, monitoring | `Context7: "AWS Backup security"` |
| `migration_guide` | Version migration | Upgrade assistance | N/A |

**To explore examples**: Navigate to `examples/<example_name>/` directory

## Quick MCP Commands Reference

### Terraform MCP Server Commands
```bash
# Resource Documentation
"Look up aws_backup_vault resource"
"Get aws_backup_plan lifecycle documentation"
"Find aws_backup_selection resource arguments"
"Check aws_backup_vault_lock_configuration"
"Validate aws_backup_framework controls"

# IAM and Security
"Find aws_iam_role for backup service"
"Get aws_kms_key encryption for backups"
"Check aws_backup_vault_policy syntax"

# Advanced Features
"aws_backup_report_plan configuration"
"aws_organizations_policy BACKUP_POLICY type"
"aws_backup continuous backup support"
```

### Context7 Server Commands
```bash
# Best Practices
"AWS Backup security best practices"
"Terraform module development guidelines"
"AWS Backup cost optimization strategies"

# Testing Patterns
"Terratest AWS Backup examples"
"Go testing retry patterns for AWS"
"Integration testing for Terraform modules"

# Performance
"Terraform performance optimization"
"AWS Backup API throttling solutions"
"Large-scale backup deployment patterns"
```

## Provider Version Management

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"  # AWS Backup features require newer versions
    }
  }
}

# Validate requirements: Terraform MCP "aws provider backup requirements"
```

## Key Module Features

1. **Comprehensive Backup Management** - Plans, vaults, selections, and lifecycle policies
2. **Audit Framework Integration** - Built-in compliance and audit capabilities
3. **Organization Policy Support** - Enterprise-wide backup governance
4. **Multi-Vault Architecture** - Complex backup scenarios with cross-region support
5. **VSS Backup Support** - Windows Volume Shadow Copy Service integration
6. **Cost Optimization** - Intelligent tiering and lifecycle management
7. **Security-First Design** - KMS encryption, vault lock, and access controls
8. **Advanced Testing Framework** - Comprehensive testing with retry logic
9. **16 Example Configurations** - From simple to enterprise-grade scenarios
10. **MCP Integration** - Real-time validation and documentation access

## Additional Resources

- **Module Documentation**: See README.md for usage
- **Security Guidelines**: SECURITY.md
- **Performance Tips**: PERFORMANCE.md
- **Troubleshooting**: TROUBLESHOOTING.md
- **Migration Guide**: MIGRATION.md
- **Testing Details**: docs/TESTING.md

*Note: This module focuses on AWS Backup best practices and patterns specific to backup and disaster recovery operations. Always validate configurations using MCP servers before deployment.*
