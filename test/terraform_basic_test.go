package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestTerraformBasicValidation tests basic Terraform validation
func TestTerraformBasicValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Upgrade:      true,
	}

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform validate"
	terraform.InitAndValidate(t, terraformOptions)
}

// TestExampleSimplePlan tests the simple plan example
func TestExampleSimplePlan(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/simple_plan",
		Upgrade:      true,
	}

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform validate"
	terraform.InitAndValidate(t, terraformOptions)
}

// TestExampleCompletePlan tests the complete plan example
func TestExampleCompletePlan(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete_plan",
		Upgrade:      true,
	}

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform validate"
	terraform.InitAndValidate(t, terraformOptions)
}

// TestExampleWindowsVSSBackup tests the Windows VSS backup example
func TestExampleWindowsVSSBackup(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/simple_plan_windows_vss_backup",
		Upgrade:      true,
	}

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform validate"
	terraform.InitAndValidate(t, terraformOptions)
}