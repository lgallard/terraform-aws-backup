# AWS Backup Feature Discovery Prompts

This document contains standardized prompts for Claude Code to ensure consistent feature discovery analysis.

## Main Discovery Prompt

```
# AWS Backup Feature Discovery Analysis

You are performing automated feature discovery for the terraform-aws-backup module to identify new AWS Backup features, deprecations, and bug fixes.

## Context
- Repository: terraform-aws-backup
- Current Provider Support: AWS Provider >= 5.0.0
- Module Structure: Main backup resources + IAM + notifications + organizations + audit manager
- Examples: 16 comprehensive examples covering backup scenarios from simple to enterprise

## Discovery Process

### Step 1: Load Current State
Read the feature tracking database to understand what's already implemented:
```bash
cat .github/feature-tracker/backup-features.json
```

### Step 2: Fetch Latest Backup Documentation

Use the Terraform MCP server to get comprehensive Backup documentation:

**Backup Resources:**
```
mcp__terraform-server__resolveProviderDocID:
- providerName: "aws"
- providerNamespace: "hashicorp"
- serviceSlug: "backup"
- providerVersion: "latest"
- providerDataType: "resources"
```

**Backup Data Sources:**
```
mcp__terraform-server__resolveProviderDocID:
- providerName: "aws"
- providerNamespace: "hashicorp"
- serviceSlug: "backup"
- providerVersion: "latest"
- providerDataType: "data-sources"
```

### Step 3: Analyze Current Implementation

Examine module structure and extract implementation details:

**Core Files to Analyze:**
- `main.tf` - Primary backup resources and locals with complex validation logic
- `iam.tf` - IAM roles and policies for backup service
- `notifications.tf` - SNS and notification configurations
- `organizations.tf` - AWS Organizations backup policies
- `selection.tf` - Resource selection logic and condition handling
- `reports.tf` - Backup reporting configurations
- `audit_manager.tf` - Audit framework configurations
- `variables.tf` - All input variables and comprehensive validation
- `outputs.tf` - Module outputs

**Examples Directory (16 Examples):**
Check `examples/*/main.tf` files to understand supported patterns:
- `simple_plan`, `complete_plan`, `multiple_plans`
- `selection_by_tags`, `selection_by_conditions`
- `cross_region_backup`
- `simple_plan_using_lock_configuration`
- `organization_backup_policy`
- `complete_audit_framework`, `simple_audit_framework`, `aws_recommended_audit_framework`
- `simple_plan_windows_vss_backup`
- `notifications_only_on_failed_jobs`
- `simple_plan_with_report`
- `cost_optimized_backup`
- `secure_backup_configuration`

### Step 4: Intelligent Comparison

Compare provider documentation against current implementation:

**New Features to Detect:**
1. **New Resources:** Any `aws_backup_*` resources not in module
2. **New Arguments:** New arguments on existing resources
3. **New Data Sources:** New `data.aws_backup_*` sources
4. **New Backup Features:** Advanced backup options, new service integrations
5. **New Security Features:** Enhanced encryption, access controls
6. **New Compliance Features:** Audit controls, compliance frameworks
7. **New Cross-Region Features:** Enhanced replication, disaster recovery
8. **New Organization Features:** Enterprise-wide backup governance
9. **New Cost Optimization:** Tiering, lifecycle management improvements
10. **New VSS Features:** Windows Volume Shadow Copy Service enhancements

**Deprecations to Find:**
1. **Deprecated Arguments:** Arguments marked for removal
2. **Deprecated Resources:** Resources being phased out
3. **Deprecated Patterns:** Backup configurations no longer recommended
4. **Deprecated API Features:** AWS Backup API changes

**Bug Fixes to Identify:**
Use Context7 MCP server to check AWS provider changelogs:
```
mcp__context7__resolve-library-id: "terraform-provider-aws"
mcp__context7__get-library-docs: topic="backup changes changelog"
```

### Step 5: Categorize and Prioritize

**Priority Classification:**
- **P0 (Critical):** Data protection vulnerabilities, backup failures
- **P1 (High):** New core backup resources, major deprecations
- **P2 (Medium):** New arguments, backup enhancements
- **P3 (Low):** Minor improvements, cosmetic changes

**Feature Categories:**
- **NEW_RESOURCE:** Entirely new backup resource type
- **NEW_ARGUMENT:** New argument on existing resource
- **NEW_DATA_SOURCE:** New data source for backup
- **ENHANCEMENT:** Improvement to existing functionality
- **DEPRECATION:** Feature being deprecated
- **BUG_FIX:** Important bug fix from provider
- **SECURITY:** Security-related update
- **COMPLIANCE:** Compliance and audit improvements
- **COST_OPTIMIZATION:** Cost management features

### Step 6: Issue Creation

For each significant finding, create GitHub issues using appropriate templates.

**Check for Duplicates First:**
```bash
gh issue list --label "auto-discovered" --state open
gh issue list --search "[FEATURE_NAME]" --state all
```

**Create Issues with Proper Data:**
```bash
# New Feature
gh issue create \
  --template .github/ISSUE_TEMPLATE/new-backup-feature.md \
  --title "feat: Add support for [FEATURE_NAME]" \
  --label "enhancement,aws-provider-update,auto-discovered" \
  --body "[DETAILED_DESCRIPTION]"

# Deprecation
gh issue create \
  --template .github/ISSUE_TEMPLATE/backup-deprecation.md \
  --title "chore: Handle deprecation of [DEPRECATED_FEATURE]" \
  --label "deprecation,breaking-change,auto-discovered" \
  --body "[DEPRECATION_DETAILS]"

# Bug Fix
gh issue create \
  --template .github/ISSUE_TEMPLATE/backup-bug-fix.md \
  --title "fix: Address [BUG_DESCRIPTION]" \
  --label "bug,aws-provider-update,auto-discovered" \
  --body "[BUG_FIX_DETAILS]"
```

### Step 7: Update Tracking Database

Update `.github/feature-tracker/backup-features.json`:

```json
{
  "metadata": {
    "last_scan": "[CURRENT_TIMESTAMP]",
    "provider_version": "[SCANNED_VERSION]",
    "scan_count": "[INCREMENTED_COUNT]"
  },
  "scan_history": [
    {
      "scan_date": "[CURRENT_TIMESTAMP]",
      "provider_version": "[SCANNED_VERSION]",
      "features_found": "[COUNT]",
      "deprecations_found": "[COUNT]",
      "fixes_found": "[COUNT]",
      "issues_created": "[ISSUE_NUMBERS]"
    }
  ],
  "discovered_features": {
    "new_resources": {
      "[RESOURCE_NAME]": {
        "discovered_date": "[DATE]",
        "provider_version": "[VERSION]",
        "issue_number": "[ISSUE_NUM]",
        "priority": "[P0/P1/P2/P3]",
        "status": "pending"
      }
    },
    // Similar structure for new_arguments, deprecations, etc.
  },
  "issues_created": [
    {
      "issue_number": "[NUM]",
      "feature_type": "[TYPE]",
      "feature_name": "[NAME]",
      "created_date": "[DATE]",
      "priority": "[PRIORITY]",
      "status": "open"
    }
  ]
}
```

## Quality Assurance Rules

**Avoid False Positives:**
1. Only flag features not already in module
2. Verify features are AWS Backup-specific (not general AWS)
3. Check if feature is already tracked as "pending"
4. Ensure feature is stable (not experimental)

**Issue Content Requirements:**
1. Include provider documentation links
2. Provide implementation examples
3. Add clear acceptance criteria
4. Estimate complexity/priority correctly
5. Include testing requirements

**Tracking Requirements:**
1. Update scan timestamp
2. Increment scan counter
3. Record all findings
4. Track issue numbers
5. Maintain history

## AWS Backup-Specific Focus Areas

**Backup Operations:**
- Backup vault management and policies
- Backup plan configuration and scheduling
- Resource selection and tagging strategies

**Data Protection:**
- Encryption at rest and in transit
- Cross-region backup and replication
- Backup lifecycle and retention policies

**Compliance & Audit:**
- Backup frameworks and controls
- Audit reporting and compliance tracking
- Organization-wide backup policies

**Recovery Operations:**
- Point-in-time recovery capabilities
- Cross-account recovery scenarios
- Automated recovery testing

**Cost Management:**
- Storage tiering and lifecycle management
- Cost allocation and tracking
- Resource utilization optimization

**Enterprise Features:**
- Organization-wide governance
- Multi-account backup strategies
- Advanced security and access controls

**Windows Integration:**
- Volume Shadow Copy Service (VSS) support
- Application-consistent backups
- Windows-specific backup features

## Success Metrics

Track these metrics in your analysis:
- Features discovered vs actually new
- Issues created vs duplicates avoided
- Priority accuracy (validated later)
- Implementation time (tracked over time)

## Expected Output Format

Provide a structured summary:

```
## AWS Backup Feature Discovery Results

**Scan Details:**
- Timestamp: [TIMESTAMP]
- Provider Version: [VERSION]
- Scan Duration: [DURATION]

**Findings Summary:**
- New Features: [COUNT] ([P0]: [COUNT], [P1]: [COUNT], [P2]: [COUNT], [P3]: [COUNT])
- Deprecations: [COUNT]
- Bug Fixes: [COUNT]
- Total Issues Created: [COUNT]

**New Features Discovered:**
1. [FEATURE_NAME] (Priority: [P1], Issue: #[NUM])
   - Type: [Resource/Argument/Data Source]
   - Description: [BRIEF_DESC]
   - Implementation Complexity: [High/Medium/Low]

**Deprecations Found:**
1. [DEPRECATED_FEATURE] (Issue: #[NUM])
   - Removal Timeline: [TIMELINE]
   - Impact: [High/Medium/Low]
   - Migration Path: [AVAILABLE/NEEDS_RESEARCH]

**Bug Fixes Identified:**
1. [BUG_DESCRIPTION] (Issue: #[NUM])
   - Fixed in Version: [VERSION]
   - Module Impact: [DESCRIPTION]

**Actions Taken:**
- Updated feature tracking database
- Created [COUNT] GitHub issues
- No duplicates found
- All issues properly labeled and categorized

**Recommendations:**
- [RECOMMENDATION_1]
- [RECOMMENDATION_2]
```

## Error Handling

If any step fails:
1. Log the specific error
2. Continue with remaining steps
3. Report partial results
4. Suggest manual review for failed areas
```

Use this prompt structure consistently for all feature discovery runs to ensure comprehensive and accurate analysis.
