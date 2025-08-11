# Test Suite with Retry Logic

This test suite includes retry logic for handling transient AWS API failures and improving test reliability.

## Retry Configuration

The retry logic can be configured using environment variables:

- `TEST_RETRY_MAX_ATTEMPTS`: Maximum number of retry attempts (default: 3)
- `TEST_RETRY_INITIAL_DELAY`: Initial delay between retries (default: 5s)
- `TEST_RETRY_MAX_DELAY`: Maximum delay between retries (default: 60s)

Example:
```bash
export TEST_RETRY_MAX_ATTEMPTS=5
export TEST_RETRY_INITIAL_DELAY=2s
export TEST_RETRY_MAX_DELAY=30s
go test -v ./...
```

## Retry Helpers

The following helper functions are available with built-in retry logic:

### Terraform Operations
- `RetryableInitAndApply(t, options)` - Init and apply with retry
- `RetryableDestroy(t, options)` - Destroy with retry
- `RetryableInit(t, options)` - Init only with retry
- `RetryablePlan(t, options)` - Plan with retry

### AWS Operations
- `RetryableAWSOperation(t, description, func)` - Wrap any AWS SDK operation

Example usage:
```go
// Terraform operations
RetryableInitAndApply(t, terraformOptions)
defer RetryableDestroy(t, terraformOptions)

// AWS operations
var output *backup.GetBackupPlanOutput
RetryableAWSOperation(t, "get backup plan", func() error {
    var err error
    output, err = backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
        BackupPlanId: aws.String(planId),
    })
    return err
})
```

## Retryable Errors

The following errors are considered retryable:
- AWS throttling errors (ThrottlingException, RequestLimitExceeded)
- Service unavailable errors
- Internal server errors
- Timeout errors
- Connection errors
- Rate limit errors (detected in error message)

Non-retryable errors (like AccessDenied, InvalidParameter) will fail immediately.

## Running Tests

### Run all tests with default retry settings:
```bash
cd test
go test -v ./...
```

### Run specific test with custom retry settings:
```bash
TEST_RETRY_MAX_ATTEMPTS=5 go test -v -run TestBasicBackupPlan
```

### Run integration tests:
```bash
# Requires AWS credentials
go test -v -timeout 30m -run TestBasicBackupPlan
go test -v -timeout 30m -run TestIAMRoleCreation
```

### Run example validation tests:
```bash
go test -v -timeout 10m -run TestExamples
```

## Monitoring Retry Behavior

When retries occur, you'll see log messages like:
```
terraform init and apply in fixtures/terraform/basic failed (attempt 1/3), retrying in 5s: ThrottlingException: Rate exceeded
```

This helps identify when AWS API limits are being hit and allows you to adjust retry configuration accordingly.
