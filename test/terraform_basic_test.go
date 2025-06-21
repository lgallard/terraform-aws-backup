package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestTerraformBasicValidation tests basic Terraform validation without AWS provider calls
func TestTerraformBasicValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Upgrade:      false,
		PlanFilePath: "/tmp/tfplan",
	}

	// Run "terraform init" and "terraform validate"
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestExampleSimplePlan tests the simple plan example
func TestExampleSimplePlan(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/simple_plan",
		Upgrade:      false,
	}

	// Run "terraform init" and "terraform validate"
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestExampleCompletePlan tests the complete plan example
func TestExampleCompletePlan(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete_plan",
		Upgrade:      false,
	}

	// Run "terraform init" and "terraform validate"
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestExampleWindowsVSSBackup tests the Windows VSS backup example
func TestExampleWindowsVSSBackup(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/simple_plan_windows_vss_backup",
		Upgrade:      false,
	}

	// Run "terraform init" and "terraform validate"
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}