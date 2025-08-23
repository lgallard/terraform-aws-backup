---
name: ⚠️ AWS Backup Feature Deprecation
about: Auto-discovered deprecated AWS Backup feature requiring action
title: "chore: Handle deprecation of [DEPRECATED_FEATURE]"
labels: ["deprecation", "breaking-change", "aws-provider-update", "auto-discovered"]
assignees: []
---

## ⚠️ AWS Backup Feature Deprecation Notice

**AWS Provider Version:** v[PROVIDER_VERSION]
**Deprecated Feature:** `[DEPRECATED_FEATURE]`
**Deprecation Date:** `[DEPRECATION_DATE]`
**Planned Removal:** `[REMOVAL_VERSION]` (if known)
**Priority:** P1-High
**Auto-detected:** ✅ `[SCAN_DATE]`

### Deprecation Details
<!-- Auto-extracted from AWS provider documentation -->
[DEPRECATION_DESCRIPTION]

### Current Usage in Module
**Files Affected:**
- [ ] `main.tf` - [USAGE_DETAILS]
- [ ] `iam.tf` - [USAGE_DETAILS]
- [ ] `notifications.tf` - [USAGE_DETAILS]
- [ ] `organizations.tf` - [USAGE_DETAILS]
- [ ] `selection.tf` - [USAGE_DETAILS]
- [ ] `reports.tf` - [USAGE_DETAILS]
- [ ] `audit_manager.tf` - [USAGE_DETAILS]
- [ ] `variables.tf` - [VARIABLE_REFERENCES]
- [ ] `outputs.tf` - [OUTPUT_REFERENCES]
- [ ] `examples/*/` - [EXAMPLE_USAGE]

**Impact Assessment:**
- **Severity:** [High/Medium/Low]
- **User Impact:** [Breaking/Non-breaking]
- **Module Components Affected:** [List of components]

### Migration Path
<!-- Auto-extracted migration guidance from provider docs -->

#### Recommended Replacement
```hcl
# OLD (Deprecated)
[OLD_CONFIGURATION]

# NEW (Recommended)
[NEW_CONFIGURATION]
```

### Action Plan

#### Phase 1: Assessment & Planning
- [ ] **Audit Current Usage**
  - [ ] Search all module files for deprecated feature usage
  - [ ] Identify all examples using the deprecated feature
  - [ ] Document impact on existing users
- [ ] **Test Migration**
  - [ ] Create test branch with new implementation
  - [ ] Validate functionality with new approach
  - [ ] Ensure backward compatibility during transition

#### Phase 2: Implementation
- [ ] **Update Module Code**
  - [ ] Replace deprecated feature with recommended alternative
  - [ ] Add conditional logic for smooth transition (if possible)
  - [ ] Update variable descriptions and validation
  - [ ] Add deprecation warnings in variable descriptions
- [ ] **Update Examples**
  - [ ] Modify all affected examples (check all 16 examples)
  - [ ] Add migration examples showing both old and new patterns
  - [ ] Update example documentation

#### Phase 3: Documentation & Communication
- [ ] **Update Documentation**
  - [ ] Add deprecation notice to README
  - [ ] Document migration steps for users
  - [ ] Update variable documentation
  - [ ] Add to CHANGELOG.md with migration guidance
- [ ] **Add Deprecation Warnings**
  - [ ] Add validation warnings for deprecated usage
  - [ ] Include migration instructions in validation messages
  - [ ] Plan timeline for complete removal

#### Phase 4: Testing & Validation
- [ ] **Comprehensive Testing**
  - [ ] Test all examples with new implementation
  - [ ] Run full test suite with backup API retry logic
  - [ ] Validate backward compatibility
  - [ ] Test upgrade scenarios
- [ ] **Quality Assurance**
  - [ ] Run `terraform fmt`, `terraform validate`
  - [ ] Run `pre-commit run --all-files`
  - [ ] Peer review migration approach

### Timeline
- **Deprecation Notice:** `[DEPRECATION_DATE]`
- **Migration Deadline:** `[MIGRATION_DEADLINE]`
- **Planned Removal:** `[REMOVAL_DATE]`
- **Our Target Migration:** `[OUR_TIMELINE]`

### Provider Documentation
- **Deprecation Notice:** [DEPRECATION_DOCS_LINK]
- **Migration Guide:** [MIGRATION_GUIDE_LINK]
- **New Feature Docs:** [NEW_FEATURE_DOCS_LINK]

### User Communication Strategy
```markdown
# Deprecation Notice Template for README

⚠️ **Deprecation Warning**: The `[DEPRECATED_FEATURE]` feature is deprecated as of AWS Provider v[VERSION].

**What's changing:** [BRIEF_DESCRIPTION]
**Timeline:** Deprecated in v[VERSION], will be removed in v[FUTURE_VERSION]
**Action required:** [MIGRATION_STEPS]

**Migration example:**
```hcl
# Before (deprecated)
[OLD_CONFIG]

# After (recommended)
[NEW_CONFIG]
```

For detailed migration instructions, see [MIGRATION_GUIDE_LINK].
```

### AWS Backup-Specific Impact Assessment
- [ ] **Backup Operations**
  - [ ] Impact on backup job execution
  - [ ] Changes to backup scheduling
  - [ ] Effect on backup vault operations
- [ ] **Data Protection**
  - [ ] Impact on backup retention policies
  - [ ] Changes to lifecycle management
  - [ ] Effect on cross-region replication
- [ ] **Compliance & Audit**
  - [ ] Impact on audit framework configurations
  - [ ] Changes to compliance reporting
  - [ ] Effect on organization policies
- [ ] **Recovery Operations**
  - [ ] Impact on restore procedures
  - [ ] Changes to point-in-time recovery
  - [ ] Effect on cross-account recovery
- [ ] **Cost Optimization**
  - [ ] Impact on storage tiering
  - [ ] Changes to backup lifecycle costs
  - [ ] Effect on resource utilization

### Breaking Change Considerations
- [ ] **Semantic Versioning Impact**
  - [ ] Determine if this requires major version bump
  - [ ] Plan release strategy (immediate patch vs next major)
  - [ ] Consider feature flag approach for transition period
- [ ] **User Migration Support**
  - [ ] Provide clear migration examples
  - [ ] Consider supporting both approaches temporarily
  - [ ] Add helpful validation messages

### Example Migration
```hcl
# Example showing before/after for module users

# BEFORE (using deprecated feature)
module "aws_backup_old" {
  source = "./terraform-aws-backup"

  vault_name = "my-backup-vault"
  [DEPRECATED_USAGE]
}

# AFTER (using new approach)
module "aws_backup_new" {
  source = "./terraform-aws-backup"

  vault_name = "my-backup-vault"
  [NEW_APPROACH]
}
```

### Testing Commands
```bash
# Test with deprecated feature (should show warnings)
terraform plan

# Test migration path
terraform init -upgrade
terraform plan

# Run comprehensive tests with retry logic
cd test/
go test -v -timeout 45m
```

### Affected Examples Analysis
Review which of the 16 examples are affected:
- [ ] `simple_plan` - Basic backup configuration
- [ ] `complete_plan` - Comprehensive setup
- [ ] `multiple_plans` - Multi-plan scenarios
- [ ] `selection_by_tags` - Tag-based selection
- [ ] `selection_by_conditions` - Condition-based selection
- [ ] `cross_region_backup` - Cross-region functionality
- [ ] `organization_backup_policy` - Org-wide policies
- [ ] `complete_audit_framework` - Audit configurations
- [ ] `secure_backup_configuration` - Security features
- [ ] `cost_optimized_backup` - Cost optimization
- [ ] Others: [LIST_OTHER_AFFECTED_EXAMPLES]

### Acceptance Criteria
- [ ] All deprecated usage removed from module
- [ ] Migration path documented and tested
- [ ] Backward compatibility maintained (if possible)
- [ ] Users have clear migration instructions
- [ ] All tests pass with new implementation
- [ ] Documentation updated with migration guidance
- [ ] Deprecation warnings implemented (if gradual migration)
- [ ] All 16 examples updated accordingly

---

### 🤖 Automation Details
**Discovery Workflow:** `feature-discovery.yml`
**Scan ID:** `[SCAN_ID]`
**Detection Method:** AWS Provider deprecation analysis
**Last Updated:** `[TIMESTAMP]`

---

*This issue was automatically created by the AWS Backup Feature Discovery workflow. Please review the auto-generated content and prioritize based on removal timeline.*