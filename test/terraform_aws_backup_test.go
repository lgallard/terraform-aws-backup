package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformAwsBackupPlanValidation tests terraform plan validation with valid configuration
func TestTerraformAwsBackupPlanValidation(t *testing.T) {
	t.Parallel()

	// Generate a unique plan name
	uniqueID := random.UniqueId()
	planName := fmt.Sprintf("test-backup-plan-%s", uniqueID)
	vaultName := fmt.Sprintf("test-backup-vault-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"enabled":            true,
			"plan_name":          planName,
			"vault_name":         vaultName,
			"vault_kms_key_id":   "alias/aws/backup",
			"tags": map[string]interface{}{
				"Environment": "test",
				"Module":      "terraform-aws-backup",
			},
			"plan": map[string]interface{}{
				planName: map[string]interface{}{
					"schedule":          "cron(0 12 * * ? *)",
					"target_vault_name": vaultName,
					"recovery_point_tags": map[string]interface{}{
						"Environment": "test",
					},
					"lifecycle": map[string]interface{}{
						"cold_storage_after": 30,
						"delete_after":       120,
					},
				},
			},
		},
	}

	// Run "terraform init" and "terraform plan" - should succeed
	terraform.InitAndPlan(t, terraformOptions)
}

// TestBackupSelectionsValidation tests backup selection validation
func TestBackupSelectionsValidation(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueID := random.UniqueId()
	planName := fmt.Sprintf("test-selection-plan-%s", uniqueID)
	vaultName := fmt.Sprintf("test-selection-vault-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"enabled":    true,
			"plan_name":  planName,
			"vault_name": vaultName,
			"plan": map[string]interface{}{
				planName: map[string]interface{}{
					"schedule":          "cron(0 12 * * ? *)",
					"target_vault_name": vaultName,
					"recovery_point_tags": map[string]interface{}{
						"Environment": "test",
					},
				},
			},
			"backup_selections": []map[string]interface{}{
				{
					"name": "test-selection",
					"resources": []string{
						"arn:aws:ec2:*:*:instance/*",
					},
					"selection_tags": []map[string]interface{}{
						{
							"type":  "STRINGEQUALS",
							"key":   "Environment",
							"value": "prod",
						},
					},
				},
			},
		},
	}

	// Run "terraform init" and "terraform plan" - should succeed
	terraform.InitAndPlan(t, terraformOptions)
}

// TestWindowsVSSValidation tests Windows VSS validation logic
func TestWindowsVSSValidation(t *testing.T) {
	t.Parallel()

	// Generate unique names
	uniqueID := random.UniqueId()
	planName := fmt.Sprintf("test-vss-plan-%s", uniqueID)
	vaultName := fmt.Sprintf("test-vss-vault-%s", uniqueID)

	// Test case 1: Windows VSS enabled with EC2 instances - should succeed
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"enabled":            true,
			"plan_name":          planName,
			"vault_name":         vaultName,
			"windows_vss_backup": true,
			"plan": map[string]interface{}{
				planName: map[string]interface{}{
					"schedule":          "cron(0 12 * * ? *)",
					"target_vault_name": vaultName,
				},
			},
			"backup_selections": []map[string]interface{}{
				{
					"name": "test-vss-selection",
					"resources": []string{
						"arn:aws:ec2:us-west-2:123456789012:instance/i-1234567890abcdef0",
					},
				},
			},
		},
	}

	// Run "terraform init" and "terraform plan" - should succeed
	terraform.InitAndPlan(t, terraformOptions)

	// Test case 2: Windows VSS enabled without EC2 instances - should fail
	terraformOptionsInvalid := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"enabled":            true,
			"plan_name":          planName + "-invalid",
			"vault_name":         vaultName + "-invalid",
			"windows_vss_backup": true,
			"plan": map[string]interface{}{
				planName + "-invalid": map[string]interface{}{
					"schedule":          "cron(0 12 * * ? *)",
					"target_vault_name": vaultName + "-invalid",
				},
			},
			"backup_selections": []map[string]interface{}{
				{
					"name": "test-vss-selection-invalid",
					"resources": []string{
						"arn:aws:dynamodb:us-west-2:123456789012:table/my-table",
					},
				},
			},
		},
	}

	// This should fail during plan due to validation
	_, err := terraform.InitAndPlanE(t, terraformOptionsInvalid)
	assert.Error(t, err, "Expected validation error for Windows VSS without EC2 instances")
}