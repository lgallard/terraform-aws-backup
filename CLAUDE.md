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

### AWS Backup-Specific Testing Framework

#### Test Structure & Organization
The testing framework includes retry logic for handling AWS Backup API limitations:

```
test/
├── go.mod                          # Go module dependencies
├── go.sum                          # Go module checksums
├── helpers.go                      # Backup-specific test helpers
├── helpers_test.go                 # Helper function tests
├── integration_test.go             # Main integration tests
└── fixtures/
    └── terraform/
        ├── basic/                  # Basic backup plan tests
        ├── conditions/             # Selection by conditions tests
        ├── cross_region/           # Cross-region backup tests
        ├── multiple_plans/         # Multiple backup plans tests
        └── notifications/          # SNS notification tests
```

#### Backup-Specific Test Categories

**1. Basic Functionality Tests**
- `TestBasicBackupPlan` - Basic backup plan and vault creation
- `TestIAMRoleCreation` - IAM role validation for backup operations
- `TestVaultLockConfiguration` - Vault lock compliance validation
- `TestBackupSelectionByTags` - Tag-based resource selection

**2. Advanced Feature Tests**
- `TestCrossRegionBackup` - Cross-region backup configuration
- `TestOrganizationBackupPolicy` - AWS Organizations policy integration
- `TestAuditFramework` - Backup audit framework validation
- `TestVSSBackupConfiguration` - Windows VSS backup support

**3. Performance & Reliability Tests**
- `TestBackupJobExecution` - Backup job success validation
- `TestRestorePointRecovery` - Recovery point validation
- `TestBackupPlanModification` - Plan modification without disruption

#### Backup Testing Best Practices

**Use Retry Logic for AWS Backup APIs:**
```go
// Example: Backup plan validation with retry
func TestBackupPlanValidation(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../fixtures/terraform/basic",
        Vars: map[string]interface{}{
            "vault_name": fmt.Sprintf("test-vault-%s", random.UniqueId()),
        },
        RetryableTerraformErrors: map[string]string{
            "ThrottlingException": "AWS Backup API throttling",
            "LimitExceededException": "AWS Backup resource limits",
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    // Validate backup plan exists with retry
    RetryableAWSOperation(t, "get backup plan", func() error {
        return ValidateBackupPlanExists(t, terraformOptions)
    })
}
```

**Test Backup Job Execution:**
```go
// Validate that backup jobs can be created and executed
func ValidateBackupJobExecution(t *testing.T, vaultName, planId string) {
    // This is a longer-running test that validates backup functionality
    // Use appropriate timeouts for backup operations
    RetryableAWSOperation(t, "validate backup job", func() error {
        return CheckBackupJobStatus(t, vaultName, planId)
    })
}
```

#### Testing Environment Variables
```bash
# Configure retry behavior for backup operations
export TEST_RETRY_MAX_ATTEMPTS=5           # Higher retry count for backup APIs
export TEST_RETRY_INITIAL_DELAY=10s        # Longer initial delay
export TEST_RETRY_MAX_DELAY=300s           # Extended max delay for backup operations

# Backup-specific test configurations
export AWS_BACKUP_TEST_REGION=us-east-1
export AWS_BACKUP_TEST_VAULT_PREFIX=terratest
export AWS_BACKUP_ENABLE_LONG_RUNNING_TESTS=false
```

### Testing Strategy
- Use Terratest for integration testing with backup-specific retry logic
- Include examples for common backup use cases
- Test resource creation, backup job execution, and destruction
- Validate outputs and state consistency
- Test different backup selection combinations
- Validate cross-region backup functionality
- Test audit framework compliance
- Validate organization policy enforcement

## Security Considerations

### AWS Backup-Specific Security Practices
- **Vault Encryption**: Always use KMS encryption for backup vaults
- **IAM Role Scoping**: Apply principle of least privilege for backup service roles
- **Cross-Account Access**: Implement secure cross-account backup sharing
- **Vault Lock Compliance**: Use vault lock for compliance and immutability
- **Access Controls**: Restrict backup vault access appropriately
- **Audit Framework**: Implement backup audit frameworks for compliance

### Backup Security Patterns

#### KMS Encryption for Backup Vaults
```hcl
# Example: Comprehensive KMS validation for backup vaults
variable "vault_kms_key_arn" {
  description = "The server-side encryption key for backup vault"
  type        = string
  default     = null

  validation {
    condition     = var.vault_kms_key_arn == null ? true : can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}$", var.vault_kms_key_arn))
    error_message = "The vault_kms_key_arn must be a valid KMS key ARN format."
  }
}

# Secure vault creation with encryption
resource "aws_backup_vault" "this" {
  count       = local.should_create_vault ? 1 : 0
  name        = var.vault_name
  kms_key_arn = var.vault_kms_key_arn

  # Force encryption by default
  force_destroy = false

  tags = local.normalized_tags
}
```

#### Vault Lock for Compliance
```hcl
# Example: Vault lock configuration with validation
variable "vault_lock_configuration" {
  description = "Vault lock configuration for compliance"
  type = object({
    enabled             = bool
    changeable_for_days = optional(number, 3)
    max_retention_days  = number
    min_retention_days  = number
  })
  default = {
    enabled             = false
    changeable_for_days = 3
    max_retention_days  = 365
    min_retention_days  = 1
  }

  validation {
    condition = var.vault_lock_configuration.enabled ? (
      var.vault_lock_configuration.min_retention_days <= var.vault_lock_configuration.max_retention_days &&
      var.vault_lock_configuration.min_retention_days >= 1 &&
      var.vault_lock_configuration.max_retention_days <= 36500  # 100 years max
    ) : true
    error_message = "When vault lock is enabled, min_retention_days must be <= max_retention_days, min >= 1, and max <= 36500."
  }
}
```

#### IAM Role Security for Backup Operations
```hcl
# Example: Secure IAM role with minimal permissions
variable "backup_service_role_permissions" {
  description = "Additional permissions for backup service role"
  type = list(object({
    effect = string
    actions = list(string)
    resources = list(string)
    condition = optional(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for perm in var.backup_service_role_permissions : 
      contains(["Allow", "Deny"], perm.effect)
    ])
    error_message = "Permission effects must be either 'Allow' or 'Deny'."
  }
}
```

#### Cross-Account Backup Security
```hcl
# Example: Secure cross-account backup sharing
variable "backup_vault_access_policy" {
  description = "Cross-account access policy for backup vault"
  type        = string
  default     = ""

  validation {
    condition = var.backup_vault_access_policy == "" ? true : (
      can(jsondecode(var.backup_vault_access_policy)) &&
      contains(jsondecode(var.backup_vault_access_policy), "Version")
    )
    error_message = "backup_vault_access_policy must be a valid JSON policy document."
  }
}

# Secure resource policy for cross-account access
resource "aws_backup_vault_policy" "this" {
  count           = var.backup_vault_access_policy != "" ? 1 : 0
  backup_vault_name = aws_backup_vault.this[0].name
  policy          = var.backup_vault_access_policy
}
```

### Organization Security Patterns
```hcl
# Example: Secure organization backup policy
variable "organization_backup_policy" {
  description = "Organization-wide backup policy configuration"
  type = object({
    enabled     = bool
    name        = string
    description = string
    target_ous  = list(string)
    backup_plans = map(object({
      target_vault_name     = string
      schedule              = string
      lifecycle             = object({
        delete_after        = number
        cold_storage_after  = optional(number)
      })
      cross_region_copy = optional(object({
        destination_vault_arn = string
        lifecycle = object({
          delete_after       = number
          cold_storage_after = optional(number)
        })
      }))
    }))
  })
  default = {
    enabled     = false
    name        = ""
    description = ""
    target_ous  = []
    backup_plans = {}
  }

  validation {
    condition = var.organization_backup_policy.enabled ? length(var.organization_backup_policy.target_ous) > 0 : true
    error_message = "When organization backup policy is enabled, at least one target OU must be specified."
  }
}

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

## AWS Backup-Specific Development Patterns

### Audit Framework Configuration
**Implement flexible audit framework management:**

```hcl
# Example: Audit framework with dynamic controls
variable "audit_framework" {
  description = "Backup audit framework configuration"
  type = object({
    create      = bool
    name        = string
    description = string
    controls = list(object({
      name            = string
      parameter_name  = optional(string)
      parameter_value = optional(string)
    }))
  })
  default = {
    create      = false
    name        = ""
    description = ""
    controls    = []
  }

  validation {
    condition = var.audit_framework.create ? (
      length(var.audit_framework.name) > 0 &&
      length(var.audit_framework.controls) > 0
    ) : true
    error_message = "When creating audit framework, name and at least one control must be specified."
  }
}

# Process controls with parameter validation
locals {
  framework_controls = [
    for control in var.audit_framework.controls : {
      name = control.name
      parameters = (
        control.parameter_name == null || control.parameter_name == "" ||
        control.parameter_value == null || control.parameter_value == ""
      ) ? [] : [{
        name  = control.parameter_name
        value = control.parameter_value
      }]
    }
  ]
}
```

### Organization Backup Policy Management
**Handle enterprise-wide backup policies:**

```hcl
# Example: Organization policy with conditional creation
resource "aws_organizations_policy" "backup_policy" {
  count = var.enable_org_policy ? 1 : 0

  name        = var.org_policy_name
  description = var.org_policy_description
  type        = "BACKUP_POLICY"
  
  content = jsonencode({
    plans = {
      for plan_name, plan in var.backup_policies : plan_name => {
        target_backup_vault_name  = plan.target_vault_name
        schedule_expression       = plan.schedule
        start_window_minutes      = plan.start_window
        completion_window_minutes = plan.completion_window
        lifecycle = {
          delete_after_days               = plan.lifecycle.delete_after
          move_to_cold_storage_after_days = plan.lifecycle.cold_storage_after
        }
        recovery_point_tags      = plan.recovery_point_tags
        copy_actions             = plan.copy_actions
        enable_continuous_backup = plan.enable_continuous_backup
      }
    }
    selections = {
      for selection_name, selection in var.backup_selections : selection_name => {
        resources     = selection.resources
        not_resources = selection.not_resources
        conditions    = selection.conditions
        tags          = selection.tags
      }
    }
  })

  targets {
    root = var.org_policy_attach_to_root
    
    dynamic "organizational_unit" {
      for_each = var.org_policy_target_ous
      content {
        arn = organizational_unit.value
      }
    }
  }
}
```

### Multi-Vault Architecture Patterns
**Support complex multi-vault scenarios:**

```hcl
# Example: Multi-vault with cross-region support
locals {
  # Vault creation logic
  should_create_vault = var.enabled && var.vault_name != null
  should_create_lock  = local.should_create_vault && var.locked

  # Cross-region vault mapping
  cross_region_vaults = {
    for vault in var.cross_region_vaults : vault.region => {
      name        = vault.name
      kms_key_arn = vault.kms_key_arn
      region      = vault.region
    }
  }

  # Plan-to-vault associations
  plan_vault_mapping = {
    for plan_name, plan in var.plans : plan_name => {
      primary_vault = plan.target_vault_name
      copy_actions = [
        for copy in try(plan.copy_actions, []) : {
          destination_backup_vault_arn = copy.destination_backup_vault_arn
          lifecycle = copy.lifecycle
        }
      ]
    }
  }
}
```

### VSS Backup Configuration
**Handle Windows Volume Shadow Copy Service backups:**

```hcl
# Example: VSS-enabled backup configuration
variable "vss_backup_configuration" {
  description = "VSS backup configuration for Windows workloads"
  type = object({
    enabled                     = bool
    backup_plan_name           = string
    application_consistent     = optional(bool, true)
    exclude_boot_volume        = optional(bool, false)
    exclude_system_volume      = optional(bool, false)
    vss_timeout_minutes        = optional(number, 10080) # 7 days
  })
  default = {
    enabled          = false
    backup_plan_name = ""
  }

  validation {
    condition = var.vss_backup_configuration.enabled ? (
      var.vss_backup_configuration.vss_timeout_minutes >= 60 &&
      var.vss_backup_configuration.vss_timeout_minutes <= 100080 # 69.5 days max
    ) : true
    error_message = "VSS timeout must be between 60 and 100080 minutes when VSS backup is enabled."
  }
}

# Validate VSS compatibility in selection resources
locals {
  vss_compatible_resources = [
    for resource in local.selection_resources : resource
    if can(regex("^arn:aws:ec2:.*:instance/.*", resource)) || 
       can(regex("^arn:aws:fsx:.*", resource))
  ]
  
  vss_validation_passed = var.vss_backup_configuration.enabled ? (
    length(local.vss_compatible_resources) > 0
  ) : true
}
```

### Performance & Cost Optimization Patterns
**Implement backup cost and performance optimization:**

```hcl
# Example: Intelligent tiering and lifecycle management
variable "backup_optimization" {
  description = "Backup cost and performance optimization settings"
  type = object({
    enable_intelligent_tiering = optional(bool, true)
    cost_optimization_rules = optional(list(object({
      rule_name           = string
      resource_types      = list(string)
      schedule_frequency  = string  # "daily", "weekly", "monthly"
      retention_policy = object({
        warm_storage_days = number
        cold_storage_days = number
        delete_after_days = number
      })
    })), [])
    cross_region_copy_rules = optional(list(object({
      destination_region    = string
      copy_tags            = optional(bool, true)
      lifecycle = object({
        delete_after_days        = number
        move_to_cold_storage_days = optional(number)
      })
    })), [])
  })
  default = {
    enable_intelligent_tiering = true
    cost_optimization_rules    = []
    cross_region_copy_rules    = []
  }
}

# Cost-optimized backup rules generation
locals {
  optimized_backup_rules = [
    for rule in var.backup_optimization.cost_optimization_rules : {
      name                      = rule.rule_name
      schedule                  = rule.schedule_frequency == "daily" ? "cron(0 3 ? * * *)" : 
                                 rule.schedule_frequency == "weekly" ? "cron(0 3 ? * SUN *)" :
                                 "cron(0 3 1 * ? *)"  # monthly
      target_vault_name        = var.vault_name
      start_window             = 60
      completion_window        = 300
      enable_continuous_backup = false
      lifecycle = {
        cold_storage_after = rule.retention_policy.cold_storage_days
        delete_after       = rule.retention_policy.delete_after_days
      }
      copy_actions = [
        for copy_rule in var.backup_optimization.cross_region_copy_rules : {
          destination_backup_vault_arn = "arn:aws:backup:${copy_rule.destination_region}:${data.aws_caller_identity.current.account_id}:backup-vault:${var.vault_name}-${copy_rule.destination_region}"
          lifecycle = copy_rule.lifecycle
        }
      ]
    }
  ]
}
```

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

## AWS Backup Example Configurations

### Basic Backup Plan
```hcl
module "backup" {
  source = "./terraform-aws-backup"

  # Basic configuration
  enabled    = true
  vault_name = "production-backup-vault"

  # Simple daily backup plan
  plans = {
    daily_backups = {
      name = "daily-backup-plan"
      rules = [{
        name              = "daily_rule"
        target_vault_name = "production-backup-vault"
        schedule          = "cron(0 3 ? * * *)"  # 3 AM daily
        start_window      = 60
        completion_window = 300
        lifecycle = {
          cold_storage_after = 30
          delete_after       = 365
        }
      }]
    }
  }

  # Resource selection by tags
  backup_selections = [{
    name      = "production-resources"
    resources = ["*"]
    conditions = [{
      string_equals = {
        key   = "aws:tag/Environment"
        value = "production"
      }
    }]
  }]

  tags = {
    Environment = "production"
    Purpose     = "backup"
  }
}
```

### Enterprise Backup with Audit Framework
```hcl
module "enterprise_backup" {
  source = "./terraform-aws-backup"

  # Multi-vault configuration
  enabled    = true
  vault_name = "enterprise-backup-vault"
  locked     = true
  min_retention_days = 30
  max_retention_days = 2555  # 7 years

  # Audit framework for compliance
  audit_framework = {
    create      = true
    name        = "enterprise-backup-audit"
    description = "Enterprise backup compliance framework"
    controls = [
      {
        name            = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
        parameter_name  = "requiredFrequencyUnit"
        parameter_value = "days"
      },
      {
        name            = "BACKUP_RECOVERY_POINT_ENCRYPTED"
      },
      {
        name            = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
        parameter_name  = "resourceTypes"
        parameter_value = "EC2,RDS,DynamoDB,EFS"
      }
    ]
  }

  # Organization backup policy
  enable_org_policy = true
  org_policy_name   = "EnterpriseBackupPolicy"
  backup_policies = {
    critical_systems = {
      target_vault_name = "enterprise-backup-vault"
      schedule          = "cron(0 2 ? * * *)"
      start_window      = 60
      completion_window = 480
      lifecycle = {
        cold_storage_after = 30
        delete_after       = 2555
      }
      enable_continuous_backup = true
      copy_actions = [{
        destination_backup_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:enterprise-backup-vault-dr"
        lifecycle = {
          cold_storage_after = 30
          delete_after       = 2555
        }
      }]
    }
  }

  tags = {
    Environment = "enterprise"
    Compliance  = "required"
    Purpose     = "backup"
  }
}
```

### Cross-Region Backup with Cost Optimization
```hcl
module "optimized_backup" {
  source = "./terraform-aws-backup"

  enabled    = true
  vault_name = "cost-optimized-vault"

  # Cost-optimized backup rules
  plans = {
    cost_optimized = {
      name = "cost-optimized-plan"
      rules = [
        {
          name              = "frequent_backup"
          target_vault_name = "cost-optimized-vault"
          schedule          = "cron(0 6,18 ? * * *)"  # Twice daily
          start_window      = 60
          completion_window = 120
          lifecycle = {
            cold_storage_after = 7    # Move to cold storage quickly
            delete_after       = 30   # Short retention for frequent backups
          }
        },
        {
          name              = "weekly_long_term"
          target_vault_name = "cost-optimized-vault"
          schedule          = "cron(0 3 ? * SUN *)"  # Weekly on Sunday
          start_window      = 60
          completion_window = 480
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 2555  # Long-term retention
          }
          copy_actions = [{
            destination_backup_vault_arn = "arn:aws:backup:us-west-2:123456789012:backup-vault:disaster-recovery-vault"
            lifecycle = {
              cold_storage_after = 30
              delete_after       = 2555
            }
          }]
        }
      ]
    }
  }

  # Selective resource backup
  backup_selections = [
    {
      name = "database-backups"
      resources = [
        "arn:aws:rds:*:*:db:*",
        "arn:aws:dynamodb:*:*:table/*"
      ]
      conditions = [{
        string_equals = {
          key   = "aws:tag/BackupTier"
          value = "critical"
        }
      }]
    },
    {
      name = "file-systems"
      resources = [
        "arn:aws:efs:*:*:file-system/*",
        "arn:aws:fsx:*:*:file-system/*"
      ]
      conditions = [{
        string_equals = {
          key   = "aws:tag/BackupTier"
          value = "standard"
        }
      }]
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "backup"
    CostCenter  = "it-operations"
  }
}
```

### VSS-Enabled Windows Backup
```hcl
module "windows_backup" {
  source = "./terraform-aws-backup"

  enabled    = true
  vault_name = "windows-vss-vault"

  # VSS-enabled backup plan for Windows
  plans = {
    windows_vss = {
      name = "windows-vss-plan"
      rules = [{
        name              = "windows_vss_rule"
        target_vault_name = "windows-vss-vault"
        schedule          = "cron(0 4 ? * * *)"  # 4 AM daily
        start_window      = 480  # 8 hours window for VSS operations
        completion_window = 1440 # 24 hours completion window
        lifecycle = {
          cold_storage_after = 30
          delete_after       = 90
        }
        enable_continuous_backup = false  # Not compatible with VSS
      }]
    }
  }

  # Target Windows instances specifically
  backup_selections = [{
    name = "windows-instances"
    resources = ["arn:aws:ec2:*:*:instance/*"]
    conditions = [
      {
        string_equals = {
          key   = "aws:tag/Platform"
          value = "Windows"
        }
      },
      {
        string_equals = {
          key   = "aws:tag/VSS"
          value = "enabled"
        }
      }
    ]
  }]

  tags = {
    Environment = "production"
    Platform    = "Windows"
    Purpose     = "vss-backup"
  }
}
```

## Provider Version Management

```hcl
# Example provider configuration for AWS Backup
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"  # AWS Backup features require newer provider versions
    }
  }
}
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
10. **Performance Optimization** - Backup job scheduling and resource optimization

*Note: This module focuses on AWS Backup best practices and patterns specific to backup and disaster recovery operations.*