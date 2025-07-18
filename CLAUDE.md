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

# Avoid: Using count when for_each is more appropriate
resource "aws_backup_plan" "this" {
  count = var.enabled ? length(var.plans) : 0
  # ...
}
```

### Variables & Validation
Use validation blocks for critical inputs where appropriate:

```hcl
# Example: Basic validation for naming conventions
variable "vault_name" {
  description = "Name of the backup vault to create"
  type        = string
  default     = null

  validation {
    condition     = var.vault_name == null ? true : can(regex("^[0-9A-Za-z-_]{2,50}$", var.vault_name))
    error_message = "The vault_name must be between 2 and 50 characters, contain only alphanumeric characters, hyphens, and underscores."
  }
}
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

### Test Coverage for New Features
**Write tests when adding new features:**
- Create corresponding test files in `test/` directory
- Add example configurations in `examples/` directory
- Use Terratest for integration testing
- Test both success and failure scenarios

### Test Coverage for Modifications
**Add tests when modifying functionalities (if missing):**
- Review existing test coverage before making changes
- Add missing tests for functionality being modified
- Ensure backward compatibility is tested
- Test edge cases and error conditions

### Testing Strategy
- Use Terratest for integration testing
- Include examples for common use cases
- Test resource creation and destruction
- Validate outputs and state consistency
- Test different input combinations

## Security Considerations

### General Security Practices
- Consider encryption requirements (KMS keys, etc.)
- Follow principle of least privilege for IAM
- Implement proper access controls
- Use secure defaults where possible

### Example Security Patterns
```hcl
# Example: KMS key validation (optional)
variable "vault_kms_key_arn" {
  description = "The server-side encryption key for backups"
  type        = string
  default     = null

  validation {
    condition     = var.vault_kms_key_arn == null ? true : can(regex("^arn:aws:kms:", var.vault_kms_key_arn))
    error_message = "The vault_kms_key_arn must be a valid KMS key ARN."
  }
}
```

## Module Development Guidelines

### Backward Compatibility
- Maintain existing variable interfaces when possible
- Use deprecation warnings for old patterns
- Provide migration guidance for breaking changes
- Document version-specific changes

### Code Quality
- Run `terraform fmt` before committing
- Use `terraform validate` to check syntax
- Consider pre-commit hooks for automated checks
- Use consistent naming conventions

## Specific Module Patterns

### Multi-Selection Support
Handle different input formats gracefully:

```hcl
# Support both legacy and new selection formats
selection_resources = flatten([
  var.selection_resources,
  [for selection in try(tolist(var.selections), []) : try(selection.resources, [])],
  [for k, selection in try(tomap(var.selections), {}) : try(selection.resources, [])],
  [for selection in var.backup_selections : try(selection.resources, [])],
  [for plan in var.plans : flatten([for selection in try(plan.selections, []) : try(selection.resources, [])])]
])
```

### Using for_each for Complex Resources
```hcl
# Example: Creating multiple backup selections
resource "aws_backup_selection" "this" {
  for_each = {
    for idx, selection in var.backup_selections : 
    "${selection.name}_${idx}" => selection
  }
  
  iam_role_arn = aws_iam_role.backup.arn
  name         = each.value.name
  plan_id      = aws_backup_plan.this[each.value.plan_name].id
  
  dynamic "resources" {
    for_each = each.value.resources
    content {
      # resource configuration
    }
  }
}
```

## Development Workflow

### Pre-commit Requirements
- Run `terraform fmt` on modified files
- Execute `terraform validate`
- Run tests for affected functionality
- Consider running security scanning tools
- Update documentation for variable changes

### Release Management
- **DO NOT manually update CHANGELOG.md** - we use release-please for automated changelog generation
- Use conventional commit messages for proper release automation
- Follow semantic versioning principles in commit messages

### Documentation Standards
- Document all variables with clear descriptions
- Include examples for complex variable structures
- Update README.md for new features
- Let release-please handle version history

## Common Patterns to Consider

1. **Prefer for_each** - Use `for_each` over `count` for better resource management
2. **Test Coverage** - Write tests for new features and missing test coverage
3. **Flexible Inputs** - Support multiple input formats where reasonable
4. **Validation Balance** - Add validation where it prevents common errors
5. **Consistent Naming** - Follow established naming conventions
6. **Resource Management** - Handle resource creation conflicts gracefully
7. **Backward Compatibility** - Maintain compatibility when possible
8. **Security Defaults** - Use secure defaults where appropriate

## Provider Version Management

```hcl
# Example provider configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
```

*Note: Version constraints should be chosen based on actual requirements and compatibility needs.*