package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestTerraformFormatCheck tests terraform formatting
func TestTerraformFormatCheck(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	// Run terraform fmt check
	terraform.RunTerraformCommand(t, terraformOptions, "fmt", "-check", "-recursive")
}

// TestAllExamplesValidation tests that all examples validate successfully
func TestAllExamplesValidation(t *testing.T) {
	examples := []string{
		"aws_recommended_audit_framework",
		"complete_audit_framework",
		"complete_plan",
		"migration_guide",
		"multiple_plans",
		"notifications_only_on_failed_jobs",
		"organization_backup_policy",
		"selection_by_conditions",
		"selection_by_tags",
		"simple_audit_framework",
		"simple_plan",
		"simple_plan_using_lock_configuration",
		"simple_plan_using_variables",
		"simple_plan_windows_vss_backup",
		"simple_plan_with_report",
	}

	for _, example := range examples {
		t.Run(example, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "../examples/" + example,
				Upgrade:      false,
			}

			// Run "terraform init" and "terraform validate"
			terraform.Init(t, terraformOptions)
			terraform.Validate(t, terraformOptions)
		})
	}
}