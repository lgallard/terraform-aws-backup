package test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/stretchr/testify/assert"
)

// TestIsRetryableError tests the isRetryableError function
func TestIsRetryableError(t *testing.T) {
	tests := []struct {
		name     string
		err      error
		expected bool
	}{
		{
			name:     "nil error",
			err:      nil,
			expected: false,
		},
		{
			name:     "AWS throttling error",
			err:      awserr.New("ThrottlingException", "Rate exceeded", nil),
			expected: true,
		},
		{
			name:     "AWS request limit error",
			err:      awserr.New("RequestLimitExceeded", "Too many requests", nil),
			expected: true,
		},
		{
			name:     "AWS internal error",
			err:      awserr.New("InternalServerError", "Internal error", nil),
			expected: true,
		},
		{
			name:     "Rate limit in message",
			err:      errors.New("Error: rate limit exceeded for resource"),
			expected: true,
		},
		{
			name:     "Timeout in message",
			err:      errors.New("operation timed out after 30 seconds"),
			expected: true,
		},
		{
			name:     "Connection refused",
			err:      errors.New("dial tcp: connection refused"),
			expected: true,
		},
		{
			name:     "Non-retryable error",
			err:      errors.New("invalid parameter value"),
			expected: false,
		},
		{
			name:     "Access denied error",
			err:      awserr.New("AccessDenied", "Access denied", nil),
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := isRetryableError(tt.err)
			assert.Equal(t, tt.expected, result,
				"isRetryableError(%v) = %v, want %v", tt.err, result, tt.expected)
		})
	}
}

// TestRetryWithConfig tests the retry logic
func TestRetryWithConfig(t *testing.T) {
	t.Run("successful operation", func(t *testing.T) {
		attempts := 0
		config := &RetryConfig{
			MaxRetries:       3,
			InitialDelay:     1 * time.Millisecond,
			MaxDelay:         10 * time.Millisecond,
			BackoffMultiplier: 2.0,
		}

		start := time.Now()
		retryWithConfig(t, config, "test operation", func() error {
			attempts++
			return nil
		})
		duration := time.Since(start)

		assert.Equal(t, 1, attempts, "Should succeed on first attempt")
		assert.Less(t, duration, 100*time.Millisecond, "Should complete quickly")
	})

	t.Run("retryable error then success", func(t *testing.T) {
		attempts := 0
		config := &RetryConfig{
			MaxRetries:       3,
			InitialDelay:     1 * time.Millisecond,
			MaxDelay:         10 * time.Millisecond,
			BackoffMultiplier: 2.0,
		}

		retryWithConfig(t, config, "test operation", func() error {
			attempts++
			if attempts < 3 {
				return awserr.New("ThrottlingException", "Rate exceeded", nil)
			}
			return nil
		})

		assert.Equal(t, 3, attempts, "Should retry twice before succeeding")
	})

	// Note: Testing non-retryable error requires a more complex mock
	// For now, we'll skip this specific test case
}

// TestCalculateBackoffDelay tests the backoff delay calculation
func TestCalculateBackoffDelay(t *testing.T) {
	config := &RetryConfig{
		InitialDelay:     100 * time.Millisecond,
		MaxDelay:         1 * time.Second,
		BackoffMultiplier: 2.0,
	}

	tests := []struct {
		attempt  int
		expected time.Duration
	}{
		{0, 100 * time.Millisecond},
		{1, 200 * time.Millisecond},
		{2, 400 * time.Millisecond},
		{3, 800 * time.Millisecond},
		{4, 1 * time.Second}, // Should cap at MaxDelay
		{5, 1 * time.Second}, // Should still cap at MaxDelay
	}

	for _, tt := range tests {
		t.Run(fmt.Sprintf("attempt_%d", tt.attempt), func(t *testing.T) {
			delay := CalculateBackoffDelay(tt.attempt, config)
			assert.Equal(t, tt.expected, delay,
				"CalculateBackoffDelay(%d) = %v, want %v", tt.attempt, delay, tt.expected)
		})
	}
}

// Note: Additional testing helpers could be added here