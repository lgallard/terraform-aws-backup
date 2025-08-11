# Testing Guide

This guide provides comprehensive information about testing the terraform-aws-backup module, including local development, CI/CD integration, and troubleshooting.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Test Structure](#test-structure)
- [Running Tests Locally](#running-tests-locally)
- [CI/CD Integration](#cicd-integration)
- [Test Types](#test-types)
- [Cost Estimates](#cost-estimates)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Prerequisites

### Required Tools

- **Go 1.21+**: Required for running Terratest
- **Terraform 1.0+**: Required for infrastructure provisioning
- **AWS CLI**: For AWS credential management
- **Git**: For version control

### AWS Setup

1. **AWS Account**: You need an AWS account with appropriate permissions
2. **AWS Credentials**: Configure AWS credentials using one of these methods:
   - AWS CLI: `aws configure`
   - Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
   - IAM roles (for CI/CD)

3. **Required IAM Permissions**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "backup:*",
           "iam:CreateRole",
           "iam:AttachRolePolicy",
           "iam:PassRole",
           "iam:GetRole",
           "iam:DeleteRole",
           "iam:DetachRolePolicy",
           "ec2:*",
           "dynamodb:*",
           "sns:*",
           "kms:*",
           "logs:*"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

### Environment Variables

Set these environment variables for testing:

```bash
# AWS Configuration
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

# Test Configuration
export TEST_RETRY_MAX_ATTEMPTS=3
export TEST_RETRY_INITIAL_DELAY=5s
export TEST_RETRY_MAX_DELAY=60s
export TF_IN_AUTOMATION=true
```

## Test Structure

The test suite is organized as follows:

```
test/
├── README.md                 # Basic test information
├── go.mod                    # Go module dependencies
├── go.sum                    # Go module checksums
├── helpers.go                # Test helper functions
├── helpers_test.go           # Helper function tests
├── integration_test.go       # Integration tests
├── examples_test.go          # Example validation tests
└── fixtures/                 # Test fixtures
    └── terraform/
        ├── basic/            # Basic backup plan test
        ├── cross_region/     # Cross-region backup test
        ├── multiple_plans/   # Multiple backup plans test
        ├── notifications/    # Backup notifications test
        └── backup_restore/   # Backup/restore cycle test
```

## Running Tests Locally

### Quick Start

```bash
# Navigate to test directory
cd test

# Run all example tests (fast)
go test -v -timeout 10m -run TestExamples

# Run basic integration tests
go test -v -timeout 30m -run TestBasicBackupPlan

# Run all integration tests (requires AWS credentials)
go test -v -timeout 60m ./...
```

### Individual Test Execution

```bash
# Run specific test
go test -v -timeout 30m -run TestBasicBackupPlan

# Run test with custom retry settings
TEST_RETRY_MAX_ATTEMPTS=5 go test -v -timeout 30m -run TestBasicBackupPlan

# Run backup restore test (long-running)
go test -v -timeout 120m -run TestBackupRestore
```

### Test Categories

#### 1. Example Tests (`TestExamples`)
- **Purpose**: Validate Terraform configuration syntax
- **Duration**: ~5-10 minutes
- **Cost**: Free (no AWS resources created)
- **Command**: `go test -v -timeout 10m -run TestExamples`

#### 2. Basic Integration Tests
- **Purpose**: Test core functionality
- **Duration**: ~15-30 minutes
- **Cost**: ~$5-10 per test run
- **Tests**:
  - `TestBasicBackupPlan`: Basic backup plan creation
  - `TestIAMRoleCreation`: IAM role creation and permissions

#### 3. Advanced Integration Tests
- **Purpose**: Test complex scenarios
- **Duration**: ~30-60 minutes
- **Cost**: ~$10-20 per test run
- **Tests**:
  - `TestMultipleBackupPlans`: Multiple backup plans
  - `TestBackupPlanWithNotifications`: SNS notifications
  - `TestCrossRegionBackup`: Cross-region backup

#### 4. Backup/Restore Tests
- **Purpose**: Test full backup and restore cycle
- **Duration**: ~60-120 minutes
- **Cost**: ~$20-50 per test run
- **Tests**:
  - `TestBackupRestore`: Complete backup/restore cycle

## CI/CD Integration

### GitHub Actions Workflows

The project includes several GitHub Actions workflows:

#### 1. Validation Workflow (`.github/workflows/validate.yml`)
- **Triggers**: Every pull request
- **Duration**: ~5 minutes
- **Cost**: Free
- **Purpose**: Validate Terraform syntax and formatting

#### 2. Security Workflow (`.github/workflows/security.yml`)
- **Triggers**: Pull requests, pushes to master, weekly schedule
- **Duration**: ~10 minutes
- **Cost**: Free
- **Purpose**: Security scanning with Checkov and tfsec

#### 3. Test Workflow (`.github/workflows/test.yml`)
- **Triggers**: Manual dispatch, weekly schedule
- **Duration**: ~60-120 minutes
- **Cost**: ~$20-50 per run
- **Purpose**: Run integration tests

### Running CI/CD Tests

#### Manual Test Execution

1. Go to the GitHub Actions tab
2. Select "Test" workflow
3. Click "Run workflow"
4. Choose whether to run integration tests
5. Click "Run workflow"

#### Scheduled Tests

- **Example tests**: Run on every pull request
- **Integration tests**: Run weekly on Mondays at 6 AM UTC
- **Security scans**: Run weekly on Mondays at midnight UTC

## Test Types

### 1. Unit Tests

Unit tests are embedded in the helper functions and validate individual components:

```bash
# Run helper function tests
go test -v -run TestHelpers
```

### 2. Integration Tests

Integration tests create real AWS resources and validate functionality:

```bash
# Run all integration tests
go test -v -timeout 60m -run TestBasicBackupPlan
go test -v -timeout 60m -run TestMultipleBackupPlans
go test -v -timeout 60m -run TestCrossRegionBackup
```

### 3. End-to-End Tests

End-to-end tests perform complete backup and restore cycles:

```bash
# Run backup/restore test
go test -v -timeout 120m -run TestBackupRestore
```

### 4. Security Tests

Security tests validate security configurations:

```bash
# Run security scans
checkov -d . --framework terraform
tfsec .
```

## Cost Estimates

### Per Test Run Costs

| Test Type | Duration | AWS Resources | Estimated Cost |
|-----------|----------|---------------|----------------|
| Example Tests | 5-10 min | None | $0 |
| Basic Integration | 15-30 min | Backup vault, IAM roles | $2-5 |
| Advanced Integration | 30-60 min | Multiple vaults, SNS, cross-region | $5-15 |
| Backup/Restore | 60-120 min | EC2, EBS, DynamoDB, backups | $10-30 |

### Monthly Cost Estimates

| Scenario | Frequency | Monthly Cost |
|----------|-----------|--------------|
| Developer Testing | Daily basic tests | $50-100 |
| CI/CD Pipeline | Weekly full tests | $20-50 |
| Production Validation | Monthly comprehensive tests | $10-30 |

### Cost Optimization Tips

1. **Use Smaller Resources**: Tests use t3.micro instances and small EBS volumes
2. **Short Retention**: Test backups are deleted after 7 days
3. **Parallel Execution**: Tests run in parallel to reduce total time
4. **Regional Testing**: Tests run in us-east-1 for lower costs
5. **Cleanup Automation**: Resources are automatically cleaned up after tests

## Troubleshooting

### Common Issues

#### 1. AWS API Rate Limiting

**Symptoms**:
- `ThrottlingException` errors
- `RequestLimitExceeded` errors
- Random test failures

**Solutions**:
```bash
# Increase retry attempts
export TEST_RETRY_MAX_ATTEMPTS=5
export TEST_RETRY_INITIAL_DELAY=10s
export TEST_RETRY_MAX_DELAY=120s

# Run tests with increased timeout
go test -v -timeout 45m -run TestBasicBackupPlan
```

#### 2. Resource Name Conflicts

**Symptoms**:
- `AlreadyExistsException` errors
- Resource creation failures
- Parallel test conflicts

**Solutions**:
- Tests use unique naming with timestamps and random IDs
- Use `TEST_UNIQUE_SUFFIX` environment variable for additional uniqueness
- Ensure proper cleanup of previous test runs

#### 3. Permission Errors

**Symptoms**:
- `AccessDenied` errors
- IAM role creation failures
- Service-linked role issues

**Solutions**:
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/USERNAME \
  --action-names backup:CreateBackupPlan \
  --resource-arns "*"
```

#### 4. Terraform State Issues

**Symptoms**:
- State lock errors
- Resource already exists errors
- Inconsistent state

**Solutions**:
```bash
# Clean up test artifacts
cd test/fixtures/terraform/basic
rm -rf .terraform* terraform.tfstate*

# Force unlock if needed (be careful!)
terraform force-unlock LOCK_ID
```

#### 5. Long Test Execution Times

**Symptoms**:
- Tests timeout before completion
- Backup/restore operations take too long
- Resource creation delays

**Solutions**:
```bash
# Increase timeout for long-running tests
go test -v -timeout 180m -run TestBackupRestore

# Use shorter retention for test backups
export TEST_BACKUP_RETENTION_DAYS=1
```

### Debugging Tips

#### 1. Enable Verbose Logging

```bash
# Enable detailed Terraform logs
export TF_LOG=DEBUG

# Enable detailed AWS logs
export AWS_SDK_LOAD_CONFIG=1
export AWS_LOG_LEVEL=debug
```

#### 2. Test Individual Components

```bash
# Test just the backup plan creation
go test -v -timeout 30m -run TestBasicBackupPlan

# Test just the IAM role creation
go test -v -timeout 30m -run TestIAMRoleCreation
```

#### 3. Manual Resource Inspection

```bash
# Check backup vaults
aws backup list-backup-vaults

# Check backup plans
aws backup list-backup-plans

# Check backup jobs
aws backup list-backup-jobs
```

### Log Analysis

#### Test Logs

Test logs include:
- Resource creation/deletion status
- AWS API call responses
- Retry attempts and backoff timing
- Validation results

#### Common Log Patterns

```
# Successful test
✓ Test files found
✓ EBS volume data found
✓ JSON data is valid

# Failed test
✗ Test files missing
✗ EBS volume data missing
✗ JSON data is invalid or missing

# Retry patterns
terraform init and apply in fixtures/terraform/basic failed (attempt 1/3), retrying in 5s: ThrottlingException
```

## Contributing

### Running Tests Before Submitting

1. **Run example tests**: `go test -v -timeout 10m -run TestExamples`
2. **Run basic integration tests**: `go test -v -timeout 30m -run TestBasicBackupPlan`
3. **Run security scans**: `checkov -d . --framework terraform`
4. **Format code**: `terraform fmt -recursive`

### Test Development Guidelines

1. **Naming**: Use descriptive test names with `Test` prefix
2. **Isolation**: Tests should be independent and not rely on each other
3. **Cleanup**: Always clean up resources in `defer` statements
4. **Retry Logic**: Use helper functions for AWS operations
5. **Documentation**: Document complex test scenarios
6. **Performance**: Keep tests as fast as possible while maintaining coverage

### Adding New Tests

1. Create test fixtures in `test/fixtures/terraform/`
2. Add test function in `integration_test.go`
3. Update GitHub Actions workflow if needed
4. Add documentation for the new test
5. Consider cost impact and execution time

### Test Standards

- **Coverage**: Aim for good coverage of critical paths
- **Reliability**: Tests should pass consistently
- **Speed**: Optimize for reasonable execution times
- **Cost**: Balance thorough testing with cost efficiency
- **Maintainability**: Keep tests simple and well-documented

## Support

If you encounter issues:

1. Check this troubleshooting guide first
2. Search existing GitHub issues
3. Review test logs for specific error messages
4. Consider AWS service limits and quotas
5. Create a new issue with:
   - Test command used
   - Complete error output
   - AWS region and account details (without sensitive info)
   - Environment details (Go version, Terraform version, etc.)

For questions about specific tests or adding new test coverage, please open a GitHub issue with the `testing` label.
