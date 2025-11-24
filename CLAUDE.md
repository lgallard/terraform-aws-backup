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

**Validation Phase:**
```bash
# AI-powered validation
Task Agent (general-purpose): "Validate implementation comprehensively"
Task Agent (Explore - thorough): "Analyze code patterns and dependencies"
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

## AI-Powered Validation & Analysis

This module uses AI-powered validation instead of traditional automated tests. Claude AI with specialized subagents provides comprehensive code analysis, validation, and quality assurance.

### Validation Philosophy

Traditional testing frameworks require maintenance, can become outdated, and may not catch semantic issues or best practice violations. AI-powered validation provides:

- **Contextual Understanding**: Analyzes code semantically, not just syntactically
- **Best Practices Enforcement**: Validates against AWS and Terraform best practices
- **Security Analysis**: Identifies potential security vulnerabilities
- **Documentation Consistency**: Ensures examples match documentation
- **Performance Optimization**: Suggests improvements based on AWS Backup patterns

### Specialized Subagents for Validation

#### 1. Explore Agent - Code Understanding & Discovery
Use the Explore agent to understand codebase structure and relationships:

```bash
# Quick exploration (basic searches)
Task Agent (Explore - quick): "Find all backup vault configurations"
Task Agent (Explore - quick): "Locate IAM role definitions for backup service"

# Medium exploration (moderate depth)
Task Agent (Explore - medium): "Analyze backup selection patterns across the module"
Task Agent (Explore - medium): "Map all cross-region backup configurations"

# Thorough exploration (comprehensive analysis)
Task Agent (Explore - very thorough): "Examine all security configurations and encryption patterns"
Task Agent (Explore - very thorough): "Analyze complete audit framework implementation"
```

#### 2. Plan Agent - Implementation Strategy & Validation
Use the Plan agent for validating implementation approaches:

```bash
# Validate new feature implementation
Task Agent (Plan - medium): "Review the implementation strategy for VSS backup support"

# Analyze refactoring impact
Task Agent (Plan - very thorough): "Evaluate impact of changing backup selection logic"

# Security validation
Task Agent (Plan - very thorough): "Validate security implementation for vault lock configuration"
```

#### 3. General-Purpose Agent - Complex Multi-Step Analysis
Use for comprehensive validation requiring multiple tools:

```bash
# Complete feature validation
Task Agent (general-purpose): "Validate the complete backup plan implementation including:
- Resource syntax correctness
- IAM permission completeness
- Security best practices
- Example configurations
- Documentation accuracy"

# Integration analysis
Task Agent (general-purpose): "Analyze integration between backup vault, KMS encryption, and SNS notifications for security compliance"
```

### AI Validation Workflow

#### For New Features
1. **Pre-Implementation Analysis**
   ```bash
   # Understand requirements
   Task Agent (Explore - medium): "Find similar patterns in existing examples"

   # Validate approach
   Task Agent (Plan - medium): "Review implementation strategy for [feature]"
   ```

2. **During Implementation**
   ```bash
   # Continuous validation
   Terraform MCP: "Validate aws_backup_[resource] syntax"
   Context7: "Check AWS Backup best practices for [feature]"
   ```

3. **Post-Implementation Validation**
   ```bash
   # Comprehensive review
   Task Agent (general-purpose): "Perform complete validation of [feature] including:
   - Terraform syntax correctness
   - AWS resource configuration
   - Security implications
   - Performance considerations
   - Documentation completeness
   - Example accuracy"
   ```

#### For Modifications
1. **Impact Analysis**
   ```bash
   Task Agent (Explore - medium): "Find all code that depends on [modified_component]"
   Task Agent (Plan - thorough): "Analyze impact of changes to [component]"
   ```

2. **Regression Prevention**
   ```bash
   Task Agent (general-purpose): "Validate that changes to [component] maintain:
   - Backward compatibility
   - Existing functionality
   - Security posture
   - Performance characteristics"
   ```

#### For Security Reviews
```bash
# Comprehensive security analysis
Task Agent (general-purpose): "Perform security audit covering:
- KMS key usage and encryption
- IAM policy least privilege
- Vault lock configurations
- Cross-account access patterns
- SNS notification security
- Audit framework compliance"
```

#### For Performance Validation
```bash
# Performance analysis
Task Agent (Explore - thorough): "Analyze resource creation patterns for potential bottlenecks"
Task Agent (general-purpose): "Validate performance implications of:
- for_each vs count usage
- Dynamic block complexity
- Local variable computation
- Data source queries"
```

### Validation Checklist

Before committing changes, run AI validation on these aspects:

#### Syntax & Structure
- [ ] Terraform syntax correctness (use `terraform validate`)
- [ ] Resource argument completeness via Terraform MCP
- [ ] Variable type definitions and constraints
- [ ] Output value definitions

#### AWS Resource Configuration
- [ ] Resource attributes match AWS API requirements
- [ ] IAM permissions follow least privilege
- [ ] KMS encryption properly configured
- [ ] Cross-region configurations valid

#### Security
- [ ] No hardcoded credentials or secrets
- [ ] KMS encryption enabled for vaults
- [ ] IAM policies use specific actions (no wildcards)
- [ ] Vault lock configured for compliance
- [ ] SNS topics encrypted

#### Best Practices
- [ ] Using `for_each` over `count`
- [ ] Descriptive resource naming
- [ ] Proper use of locals for complex logic
- [ ] Appropriate use of dynamic blocks
- [ ] Efficient data source queries

#### Documentation
- [ ] Variable descriptions clear and complete
- [ ] Output descriptions meaningful
- [ ] README.md updated for new features
- [ ] Examples provided and validated
- [ ] CLAUDE.md updated with patterns

### AI Validation Examples

#### Example 1: Validating New Backup Plan Feature
```bash
# Step 1: Explore existing patterns
Task Agent (Explore - medium): "Analyze all aws_backup_plan resources and their rule configurations across examples"

# Step 2: Validate implementation approach
Task Agent (Plan - thorough): "Review implementation strategy for adding continuous backup support to backup plans"

# Step 3: Comprehensive validation
Task Agent (general-purpose): "Validate continuous backup implementation:
1. Check aws_backup_plan syntax for enable_continuous_backup argument
2. Verify compatible resource types (EFS, RDS, etc.)
3. Validate IAM permissions for continuous backup
4. Review security implications
5. Check example configurations
6. Verify documentation accuracy"
```

#### Example 2: Security Audit of Vault Configuration
```bash
Task Agent (general-purpose): "Perform security audit of aws_backup_vault configurations:
1. Verify KMS encryption is enforced
2. Check vault access policies for least privilege
3. Validate vault lock configurations
4. Review cross-account access patterns
5. Analyze SNS notification encryption
6. Check for compliance with audit frameworks"
```

#### Example 3: Performance Analysis of Selection Logic
```bash
Task Agent (Explore - thorough): "Analyze backup selection resource patterns"

Task Agent (general-purpose): "Evaluate performance of selection logic:
1. Analyze for_each vs count usage
2. Review dynamic block complexity
3. Check local variable computations
4. Validate resource filtering efficiency
5. Identify potential bottlenecks for large-scale deployments"
```

### Integration with Development Workflow

Replace traditional test execution with AI validation:

**Before (with traditional tests):**
```bash
cd test && go test -v -timeout 60m
```

**Now (with AI validation):**
```bash
# Request comprehensive AI validation
Task Agent (general-purpose): "Validate all module changes:
1. Terraform syntax and resource configurations
2. Security best practices and encryption
3. IAM permissions and policies
4. Performance patterns (for_each, locals, etc.)
5. Documentation and examples accuracy
6. Backward compatibility"
```

### Advantages of AI Validation

1. **Semantic Understanding**: Catches issues traditional tests miss
2. **Best Practices**: Enforces AWS and Terraform patterns automatically
3. **Security Focus**: Identifies vulnerabilities beyond test coverage
4. **No Maintenance**: No test code to maintain or update
5. **Comprehensive**: Analyzes code, documentation, and examples together
6. **Adaptive**: Stays current with AWS and Terraform changes
7. **Contextual**: Understands intent and architectural patterns

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
3. Request AI validation for affected functionality (see AI-Powered Validation section)
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

# Validation Patterns
"Terraform module validation strategies"
"AWS resource configuration best practices"
"Infrastructure as code quality assurance"

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
8. **AI-Powered Validation** - Comprehensive validation using specialized Claude AI subagents
9. **16 Example Configurations** - From simple to enterprise-grade scenarios
10. **MCP Integration** - Real-time validation and documentation access

## Additional Resources

- **Module Documentation**: See README.md for usage
- **Security Guidelines**: SECURITY.md
- **Performance Tips**: PERFORMANCE.md
- **Troubleshooting**: TROUBLESHOOTING.md
- **Migration Guide**: MIGRATION.md
- **AI Validation Guide**: See "AI-Powered Validation & Analysis" section above

*Note: This module focuses on AWS Backup best practices and patterns specific to backup and disaster recovery operations. Always validate configurations using AI-powered analysis and MCP servers before deployment.*
