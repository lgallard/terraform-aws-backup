package test

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExamplesValidation(t *testing.T) {
	t.Parallel()

	examples := []string{
		"simple_plan",
		"complete_plan",
		"selection_by_tags",
		"selection_by_conditions",
		"simple_plan_with_report",
		"simple_plan_using_variables",
		"simple_plan_using_lock_configuration",
		"simple_plan_windows_vss_backup",
		"organization_backup_policy",
		"multiple_plans",
		"aws_recommended_audit_framework",
		"complete_audit_framework",
		"simple_audit_framework",
	}

	for _, example := range examples {
		example := example // capture range variable
		t.Run(fmt.Sprintf("Example_%s", example), func(t *testing.T) {
			t.Parallel()

			// Skip if example directory doesn't exist
			exampleDir := filepath.Join("..", "examples", example)
			if _, err := os.Stat(exampleDir); os.IsNotExist(err) {
				t.Skipf("Example directory %s does not exist", exampleDir)
			}

			terraformOptions := &terraform.Options{
				TerraformDir: exampleDir,
				NoColor:      true,
				PlanFilePath: "tfplan",
			}

			// Clean up plan file after test
			defer func() {
				planFile := filepath.Join(exampleDir, "tfplan")
				if _, err := os.Stat(planFile); err == nil {
					os.Remove(planFile)
				}
			}()

			// Init and validate
			RetryableInit(t, terraformOptions)
			
			// Run terraform plan to validate configuration
			RetryablePlan(t, terraformOptions)
			
			// Validate that plan was created successfully
			planFile := filepath.Join(exampleDir, "tfplan")
			assert.FileExists(t, planFile, "Plan file should be created")
		})
	}
}

func TestExamplesWithCustomVariables(t *testing.T) {
	t.Parallel()

	// Test examples that support custom variables
	testCases := []struct {
		name         string
		exampleDir   string
		vars         map[string]interface{}
		skipApply    bool
		description  string
	}{
		{
			name:       "SimpleVaultBackup",
			exampleDir: "simple_plan",
			vars: map[string]interface{}{
				"plan_name":        "test-backup-plan",
				"vault_name":       "test-backup-vault",
				"backup_selection_name": "test-backup-selection",
			},
			skipApply:   true,
			description: "Test simple backup plan with custom variables",
		},
		{
			name:       "TagBasedSelection",
			exampleDir: "selection_by_tags",
			vars: map[string]interface{}{
				"plan_name": "test-tag-backup-plan",
				"vault_name": "test-tag-backup-vault",
			},
			skipApply:   true,
			description: "Test tag-based backup selection",
		},
		{
			name:       "ConditionBasedSelection",
			exampleDir: "selection_by_conditions",
			vars: map[string]interface{}{
				"plan_name": "test-condition-backup-plan",
				"vault_name": "test-condition-backup-vault",
			},
			skipApply:   true,
			description: "Test condition-based backup selection",
		},
	}

	for _, tc := range testCases {
		tc := tc // capture range variable
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			// Skip if example directory doesn't exist
			exampleDir := filepath.Join("..", "examples", tc.exampleDir)
			if _, err := os.Stat(exampleDir); os.IsNotExist(err) {
				t.Skipf("Example directory %s does not exist", exampleDir)
			}

			terraformOptions := &terraform.Options{
				TerraformDir: exampleDir,
				NoColor:      true,
				Vars:         tc.vars,
				PlanFilePath: fmt.Sprintf("tfplan-%s", tc.name),
			}

			// Clean up plan file after test
			defer func() {
				planFile := filepath.Join(exampleDir, fmt.Sprintf("tfplan-%s", tc.name))
				if _, err := os.Stat(planFile); err == nil {
					os.Remove(planFile)
				}
			}()

			// Init and validate
			RetryableInit(t, terraformOptions)
			
			// Run terraform plan with custom variables
			RetryablePlan(t, terraformOptions)
			
			// Validate that plan was created successfully
			planFile := filepath.Join(exampleDir, fmt.Sprintf("tfplan-%s", tc.name))
			assert.FileExists(t, planFile, "Plan file should be created with custom variables")
		})
	}
}

func TestConditionsVariableTypes(t *testing.T) {
	t.Parallel()

	// Test that the conditions variable accepts the proper structure
	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures/terraform/conditions",
		NoColor:      true,
		PlanFilePath: "tfplan-conditions",
	}

	// Clean up plan file after test
	defer func() {
		planFile := filepath.Join("./fixtures/terraform/conditions", "tfplan-conditions")
		if _, err := os.Stat(planFile); err == nil {
			os.Remove(planFile)
		}
	}()

	// Init and validate
	RetryableInit(t, terraformOptions)
	
	// Run terraform plan to validate the conditions structure works
	RetryablePlan(t, terraformOptions)
	
	// Validate that plan was created successfully
	planFile := filepath.Join("./fixtures/terraform/conditions", "tfplan-conditions")
	assert.FileExists(t, planFile, "Plan file should be created for conditions test")
}

func TestExampleTerraformFiles(t *testing.T) {
	t.Parallel()

	examples := []string{
		"simple_plan",
		"complete_plan",
		"selection_by_tags",
		"selection_by_conditions",
		"multiple_plans",
	}

	for _, example := range examples {
		example := example // capture range variable
		t.Run(fmt.Sprintf("TerraformFiles_%s", example), func(t *testing.T) {
			t.Parallel()

			exampleDir := filepath.Join("..", "examples", example)
			
			// Skip if example directory doesn't exist
			if _, err := os.Stat(exampleDir); os.IsNotExist(err) {
				t.Skipf("Example directory %s does not exist", exampleDir)
			}

			// Check that main.tf exists (required for all examples)
			mainFile := filepath.Join(exampleDir, "main.tf")
			assert.FileExists(t, mainFile, fmt.Sprintf("main.tf should exist in example %s", example))

			// Check that variables.tf exists (optional for some examples)
			variablesFile := filepath.Join(exampleDir, "variables.tf")
			if _, err := os.Stat(variablesFile); err == nil {
				assert.FileExists(t, variablesFile, fmt.Sprintf("variables.tf should exist if present in example %s", example))
			} else {
				t.Logf("variables.tf not found in example %s (optional)", example)
			}

			// Check that versions.tf exists (if present)
			versionsFile := filepath.Join(exampleDir, "versions.tf")
			if _, err := os.Stat(versionsFile); err == nil {
				assert.FileExists(t, versionsFile, "versions.tf should exist if present")
			}

			// Check that README.md exists
			readmeFile := filepath.Join(exampleDir, "README.md")
			assert.FileExists(t, readmeFile, fmt.Sprintf("README.md should exist in example %s", example))
		})
	}
}