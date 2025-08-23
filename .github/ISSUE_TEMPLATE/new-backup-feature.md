---
name: 🚀 New AWS Backup Feature
about: Auto-discovered new AWS Backup feature for implementation
title: "feat: Add support for [FEATURE_NAME]"
labels: ["enhancement", "aws-provider-update", "auto-discovered"]
assignees: []
---

## 🚀 New AWS Backup Feature Discovery

**AWS Provider Version:** v[PROVIDER_VERSION]
**Feature Type:** [Resource/Argument/Data Source]
**Priority:** [P0-Critical/P1-High/P2-Medium/P3-Low]
**Auto-detected:** ✅ `[SCAN_DATE]`

### Description
<!-- Auto-extracted from AWS provider documentation -->
[FEATURE_DESCRIPTION]

### Provider Documentation
- **Provider Docs:** [PROVIDER_DOCS_LINK]
- **AWS Service Docs:** [AWS_DOCS_LINK]
- **Terraform Registry:** [REGISTRY_LINK]

### Implementation Requirements

#### Code Changes
- [ ] Add to `main.tf` or relevant module file
- [ ] Add input variables to `variables.tf`
- [ ] Add outputs to `outputs.tf` (if applicable)
- [ ] Update locals and validation logic (if needed)
- [ ] Handle conditional resource creation
- [ ] Update IAM policies in `iam.tf` (if applicable)
- [ ] Update notifications in `notifications.tf` (if applicable)
- [ ] Update organization policies in `organizations.tf` (if applicable)
- [ ] Update audit configurations in `audit_manager.tf` (if applicable)

#### Examples & Documentation
- [ ] Create example in `examples/[feature-name]/`
- [ ] Add to existing comprehensive examples (complete, secure, etc.)
- [ ] Update main `README.md`
- [ ] Add to `CHANGELOG.md` (will be automated by release-please)

#### Testing & Validation
- [ ] Add Terratest in `test/integration_test.go`
- [ ] Add test fixtures in `test/fixtures/terraform/[feature-name]/`
- [ ] Test with existing example scenarios
- [ ] Run `terraform fmt`, `terraform validate`
- [ ] Run `pre-commit run --all-files`

#### Quality Assurance
- [ ] Follow existing code patterns and conventions
- [ ] Add proper variable validation rules
- [ ] Include appropriate default values
- [ ] Add comprehensive variable descriptions
- [ ] Ensure backward compatibility

### Example Configuration
```hcl
# Auto-generated example from provider documentation
module "aws_backup" {
  source = "./terraform-aws-backup"

  vault_name = "my-backup-vault"
  
  # New feature implementation
  [FEATURE_EXAMPLE]

  tags = {
    Environment = "production"
    Feature     = "[FEATURE_NAME]"
  }
}
```

### Expected Outputs
```hcl
# If this feature provides new outputs
output "[feature_output]" {
  description = "[Output description]"
  value       = [output_reference]
}
```

### Testing Commands
```bash
# Test the specific example
cd examples/[feature-name]
terraform init
terraform plan
terraform apply
terraform destroy

# Run comprehensive tests
cd test/
go test -v -timeout 45m -run TestTerraformBackup[FeatureName]

# Full test suite
go test -v -timeout 60m ./...
```

### Implementation Notes
<!-- Additional context or considerations -->
- [ ] **Backward Compatibility**: Ensure changes don't break existing configurations
- [ ] **Default Values**: Use sensible defaults that maintain current behavior
- [ ] **Validation**: Add appropriate variable validation where needed
- [ ] **Dependencies**: Check for new required provider features or versions
- [ ] **Performance**: Consider impact on backup operation timing
- [ ] **Cost**: Evaluate cost implications of new features

### AWS Backup-Specific Considerations
- [ ] **Vault Impact**: How does this affect backup vault configuration?
- [ ] **Plan Integration**: Does this require changes to backup plans?
- [ ] **Selection Logic**: Impact on resource selection patterns
- [ ] **Cross-Region**: Compatibility with cross-region backup scenarios
- [ ] **Organization**: Impact on organization-wide backup policies
- [ ] **Compliance**: Effect on audit frameworks and compliance
- [ ] **Recovery**: Impact on backup recovery procedures
- [ ] **Lifecycle**: Integration with backup lifecycle policies
- [ ] **VSS Support**: Compatibility with Windows VSS backups
- [ ] **Notification**: Integration with backup job notifications

### Acceptance Criteria
- [ ] Feature implemented following module patterns
- [ ] All tests pass with retry logic for backup APIs
- [ ] Examples work as documented
- [ ] Pre-commit hooks pass
- [ ] Documentation complete and accurate
- [ ] No breaking changes to existing functionality
- [ ] Feature works with all 16 existing examples
- [ ] Backup-specific patterns maintained
- [ ] IAM permissions properly configured
- [ ] Cross-account scenarios considered

### Provider Compatibility
**Minimum AWS Provider Version:** `>= [MIN_VERSION]`
**Terraform Version:** `>= 1.0` (current module requirement)

### Related Examples
Which of the 16 examples might be affected or enhanced:
- [ ] `simple_plan` - Basic backup functionality
- [ ] `complete_plan` - Comprehensive backup setup
- [ ] `multiple_plans` - Multi-plan scenarios
- [ ] `cross_region_backup` - Cross-region functionality
- [ ] `organization_backup_policy` - Organization-wide policies
- [ ] `complete_audit_framework` - Audit and compliance
- [ ] `secure_backup_configuration` - Security hardening
- [ ] `cost_optimized_backup` - Cost optimization
- [ ] Other examples: [LIST_AFFECTED_EXAMPLES]

---

### 🤖 Automation Details
**Discovery Workflow:** `feature-discovery.yml`
**Scan ID:** `[SCAN_ID]`
**Detection Method:** Terraform MCP Server analysis
**Last Updated:** `[TIMESTAMP]`

---

*This issue was automatically created by the AWS Backup Feature Discovery workflow. Please review the auto-generated content and update as needed before implementation.*