package test

import (
	"fmt"
	"math"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/awserr"
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