package test

import (
	"fmt"
	"math"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

const (
	// Default retry configuration
	defaultMaxRetries = 3
	defaultInitialDelay = 5 * time.Second
	defaultMaxDelay = 60 * time.Second
	defaultBackoffMultiplier = 2.0
)

// RetryConfig holds configuration for retry behavior
type RetryConfig struct {
	MaxRetries       int
	InitialDelay     time.Duration
	MaxDelay         time.Duration
	BackoffMultiplier float64
}

// DefaultRetryConfig returns the default retry configuration
func DefaultRetryConfig() *RetryConfig {
	return &RetryConfig{
		MaxRetries:       getEnvAsInt("TEST_RETRY_MAX_ATTEMPTS", defaultMaxRetries),
		InitialDelay:     getEnvAsDuration("TEST_RETRY_INITIAL_DELAY", defaultInitialDelay),
		MaxDelay:         getEnvAsDuration("TEST_RETRY_MAX_DELAY", defaultMaxDelay),
		BackoffMultiplier: defaultBackoffMultiplier,
	}
}

// RetryableInitAndApply runs terraform init and apply with retry logic
func RetryableInitAndApply(t *testing.T, options *terraform.Options) {
	retryableInitAndApplyWithConfig(t, options, DefaultRetryConfig())
}

// RetryableInitAndApplyWithConfig runs terraform init and apply with custom retry config
func retryableInitAndApplyWithConfig(t *testing.T, options *terraform.Options, config *RetryConfig) {
	retryWithConfig(t, config, fmt.Sprintf("terraform init and apply in %s", options.TerraformDir), func() error {
		_, err := terraform.InitAndApplyE(t, options)
		return err
	})
}

// RetryableDestroy runs terraform destroy with retry logic
func RetryableDestroy(t *testing.T, options *terraform.Options) {
	retryableDestroyWithConfig(t, options, DefaultRetryConfig())
}

// RetryableDestroyWithConfig runs terraform destroy with custom retry config
func retryableDestroyWithConfig(t *testing.T, options *terraform.Options, config *RetryConfig) {
	retryWithConfig(t, config, fmt.Sprintf("terraform destroy in %s", options.TerraformDir), func() error {
		_, err := terraform.DestroyE(t, options)
		return err
	})
}

// RetryableInit runs terraform init with retry logic
func RetryableInit(t *testing.T, options *terraform.Options) {
	retryableInitWithConfig(t, options, DefaultRetryConfig())
}

// RetryableInitWithConfig runs terraform init with custom retry config
func retryableInitWithConfig(t *testing.T, options *terraform.Options, config *RetryConfig) {
	retryWithConfig(t, config, fmt.Sprintf("terraform init in %s", options.TerraformDir), func() error {
		_, err := terraform.InitE(t, options)
		return err
	})
}

// RetryablePlan runs terraform plan with retry logic
func RetryablePlan(t *testing.T, options *terraform.Options) {
	retryablePlanWithConfig(t, options, DefaultRetryConfig())
}

// RetryablePlanWithConfig runs terraform plan with custom retry config
func retryablePlanWithConfig(t *testing.T, options *terraform.Options, config *RetryConfig) {
	retryWithConfig(t, config, fmt.Sprintf("terraform plan in %s", options.TerraformDir), func() error {
		_, err := terraform.PlanE(t, options)
		return err
	})
}

// RetryWithConfig executes a function with exponential backoff retry logic
func retryWithConfig(t *testing.T, config *RetryConfig, description string, fn func() error) {
	var lastErr error
	delay := config.InitialDelay

	for attempt := 0; attempt < config.MaxRetries; attempt++ {
		lastErr = fn()
		if lastErr == nil {
			// Success!
			return
		}

		// Check if this is a retryable error
		if !isRetryableError(lastErr) {
			t.Fatalf("%s failed with non-retryable error: %v", description, lastErr)
			return
		}

		// This is the last attempt
		if attempt == config.MaxRetries-1 {
			break
		}

		// Log the retry attempt
		t.Logf("%s failed (attempt %d/%d), retrying in %v: %v",
			description, attempt+1, config.MaxRetries, delay, lastErr)

		// Wait before retrying
		time.Sleep(delay)

		// Calculate next delay with exponential backoff
		delay = time.Duration(float64(delay) * config.BackoffMultiplier)
		if delay > config.MaxDelay {
			delay = config.MaxDelay
		}
	}

	// All retries exhausted
	t.Fatalf("%s failed after %d attempts: %v", description, config.MaxRetries, lastErr)
}

// isRetryableError determines if an error is retryable
func isRetryableError(err error) bool {
	if err == nil {
		return false
	}

	// Check for AWS-specific errors
	if awsErr, ok := err.(awserr.Error); ok {
		switch awsErr.Code() {
		case "RequestLimitExceeded",
			"Throttling",
			"ThrottlingException",
			"TooManyRequestsException",
			"ProvisionedThroughputExceededException",
			"ServiceUnavailable",
			"InternalServerError",
			"InternalError":
			return true
		}
	}

	// Check for common retryable error patterns in error messages
	errStr := strings.ToLower(err.Error())
	retryablePatterns := []string{
		"rate exceeded",
		"rate limit",
		"throttle",
		"too many requests",
		"service unavailable",
		"temporary failure",
		"timed out",
		"timeout",
		"connection refused",
		"connection reset",
		"no such host",
		"internal server error",
		"bad gateway",
		"gateway timeout",
		"conflict",
		"concurrent",
	}

	for _, pattern := range retryablePatterns {
		if strings.Contains(errStr, pattern) {
			return true
		}
	}

	return false
}

// Helper functions for environment variables
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var intValue int
		if _, err := fmt.Sscanf(value, "%d", &intValue); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if duration, err := time.ParseDuration(value); err == nil {
			return duration
		}
	}
	return defaultValue
}

// RetryableAWSOperation wraps AWS SDK operations with retry logic
func RetryableAWSOperation(t *testing.T, description string, fn func() error) {
	retryableAWSOperationWithConfig(t, description, fn, DefaultRetryConfig())
}

// RetryableAWSOperationWithConfig wraps AWS SDK operations with custom retry config
func retryableAWSOperationWithConfig(t *testing.T, description string, fn func() error, config *RetryConfig) {
	retryWithConfig(t, config, description, fn)
}

// CalculateBackoffDelay calculates the delay for a given attempt
func CalculateBackoffDelay(attempt int, config *RetryConfig) time.Duration {
	delay := time.Duration(float64(config.InitialDelay) * math.Pow(config.BackoffMultiplier, float64(attempt)))
	if delay > config.MaxDelay {
		return config.MaxDelay
	}
	return delay
}

// Enhanced unique naming functions for better test isolation

// GenerateUniqueTestID generates a unique test identifier with enhanced collision avoidance
func GenerateUniqueTestID(t *testing.T) string {
	// Use test name (sanitized), timestamp, and random ID for maximum uniqueness
	testName := sanitizeTestName(t.Name())
	timestamp := strconv.FormatInt(time.Now().UnixNano(), 10)
	randomID := strings.ToLower(random.UniqueId())
	suffix := os.Getenv("TEST_UNIQUE_SUFFIX")

	baseID := fmt.Sprintf("%s-%s-%s", testName, timestamp, randomID)
	if suffix != "" {
		baseID = fmt.Sprintf("%s-%s", baseID, suffix)
	}

	// Ensure the ID doesn't exceed AWS resource name limits
	if len(baseID) > 50 {
		baseID = baseID[:50]
	}

	return baseID
}

// GenerateUniqueResourceName generates a unique resource name with prefix and enhanced collision avoidance
func GenerateUniqueResourceName(t *testing.T, prefix string) string {
	uniqueID := GenerateUniqueTestID(t)
	resourceName := fmt.Sprintf("%s-%s", prefix, uniqueID)

	// Ensure the name doesn't exceed AWS resource name limits
	if len(resourceName) > 63 {
		resourceName = resourceName[:63]
	}

	return resourceName
}

// GenerateUniqueBackupPlanName generates a unique backup plan name
func GenerateUniqueBackupPlanName(t *testing.T) string {
	return GenerateUniqueResourceName(t, "test-backup-plan")
}

// GenerateUniqueBackupVaultName generates a unique backup vault name
func GenerateUniqueBackupVaultName(t *testing.T) string {
	return GenerateUniqueResourceName(t, "test-backup-vault")
}

// GenerateUniqueSelectionName generates a unique backup selection name
func GenerateUniqueSelectionName(t *testing.T) string {
	return GenerateUniqueResourceName(t, "test-backup-selection")
}

// GenerateUniqueTopicName generates a unique SNS topic name
func GenerateUniqueTopicName(t *testing.T) string {
	return GenerateUniqueResourceName(t, "test-backup-topic")
}

// GenerateUniqueRoleName generates a unique IAM role name
func GenerateUniqueRoleName(t *testing.T) string {
	return GenerateUniqueResourceName(t, "test-backup-role")
}

// GenerateRegionSpecificResourceName generates a region-specific resource name
func GenerateRegionSpecificResourceName(t *testing.T, prefix, region string) string {
	uniqueID := GenerateUniqueTestID(t)
	resourceName := fmt.Sprintf("%s-%s-%s", prefix, region, uniqueID)

	// Ensure the name doesn't exceed AWS resource name limits
	if len(resourceName) > 63 {
		resourceName = resourceName[:63]
	}

	return resourceName
}

// sanitizeTestName removes invalid characters from test names for resource naming
func sanitizeTestName(testName string) string {
	// Remove package prefix and path separators
	parts := strings.Split(testName, "/")
	if len(parts) > 0 {
		testName = parts[len(parts)-1]
	}

	// Replace invalid characters with hyphens
	sanitized := strings.ReplaceAll(testName, "_", "-")
	sanitized = strings.ReplaceAll(sanitized, " ", "-")
	sanitized = strings.ReplaceAll(sanitized, ".", "-")
	sanitized = strings.ToLower(sanitized)

	// Ensure it starts with a letter (required for some AWS resources)
	if len(sanitized) > 0 && !isLetter(sanitized[0]) {
		sanitized = "test-" + sanitized
	}

	// Truncate if too long
	if len(sanitized) > 20 {
		sanitized = sanitized[:20]
	}

	return sanitized
}

// isLetter checks if a byte is a letter
func isLetter(b byte) bool {
	return (b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z')
}

// GetTestRegion returns the test region with fallback to us-east-1
func GetTestRegion() string {
	region := os.Getenv("AWS_DEFAULT_REGION")
	if region == "" {
		region = "us-east-1"
	}
	return region
}

// GetCrossRegion returns a different region for cross-region testing
func GetCrossRegion() string {
	primaryRegion := GetTestRegion()
	switch primaryRegion {
	case "us-east-1":
		return "us-west-2"
	case "us-west-2":
		return "us-east-1"
	case "eu-west-1":
		return "eu-central-1"
	case "ap-southeast-1":
		return "ap-northeast-1"
	default:
		return "us-west-2"
	}
}

// ValidateResourceName validates that a resource name meets AWS naming requirements
func ValidateResourceName(name string) error {
	if len(name) < 2 {
		return fmt.Errorf("resource name must be at least 2 characters long")
	}
	if len(name) > 63 {
		return fmt.Errorf("resource name must be 63 characters or less")
	}
	if !isLetter(name[0]) {
		return fmt.Errorf("resource name must start with a letter")
	}
	for _, char := range name {
		if !isValidNameChar(char) {
			return fmt.Errorf("resource name contains invalid character: %c", char)
		}
	}
	return nil
}

// isValidNameChar checks if a character is valid for AWS resource names
func isValidNameChar(char rune) bool {
	return (char >= 'a' && char <= 'z') ||
		   (char >= 'A' && char <= 'Z') ||
		   (char >= '0' && char <= '9') ||
		   char == '-' || char == '_'
}

// TestResourceCleanup helps ensure resources are cleaned up after tests
type TestResourceCleanup struct {
	resources []string
	t         *testing.T
}

// NewTestResourceCleanup creates a new cleanup helper
func NewTestResourceCleanup(t *testing.T) *TestResourceCleanup {
	return &TestResourceCleanup{
		resources: make([]string, 0),
		t:         t,
	}
}

// AddResource adds a resource to the cleanup list
func (c *TestResourceCleanup) AddResource(resource string) {
	c.resources = append(c.resources, resource)
}

// LogResources logs all resources that were created during the test
func (c *TestResourceCleanup) LogResources() {
	if len(c.resources) > 0 {
		c.t.Logf("Resources created during test %s:", c.t.Name())
		for _, resource := range c.resources {
			c.t.Logf("  - %s", resource)
		}
	}
}