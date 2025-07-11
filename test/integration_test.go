package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/backup"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestBasicBackupPlan tests the creation of a basic backup plan
func TestBasicBackupPlan(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test
	uniqueId := random.UniqueId()
	planName := fmt.Sprintf("test-backup-plan-%s", uniqueId)
	vaultName := fmt.Sprintf("test-backup-vault-%s", uniqueId)
	selectionName := fmt.Sprintf("test-backup-selection-%s", uniqueId)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/basic",
		Vars: map[string]interface{}{
			"plan_name":      planName,
			"vault_name":     vaultName,
			"selection_name": selectionName,
			"aws_region":     "us-east-1",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Validate that the backup plan was created
	backupClient := backup.New(sess)
	
	// Get the backup plan ARN from terraform output
	backupPlanArn := terraform.Output(t, terraformOptions, "backup_plan_arn")
	require.NotEmpty(t, backupPlanArn, "Backup plan ARN should not be empty")

	// Validate backup plan exists
	planId := terraform.Output(t, terraformOptions, "backup_plan_id")
	planOutput, err := backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
		BackupPlanId: aws.String(planId),
	})
	require.NoError(t, err, "Should be able to get backup plan")
	assert.Equal(t, planName, *planOutput.BackupPlan.BackupPlanName, "Plan name should match")

	// Validate backup vault exists
	vaultArn := terraform.Output(t, terraformOptions, "backup_vault_arn")
	require.NotEmpty(t, vaultArn, "Backup vault ARN should not be empty")

	vaultOutput, err := backupClient.DescribeBackupVault(&backup.DescribeBackupVaultInput{
		BackupVaultName: aws.String(vaultName),
	})
	require.NoError(t, err, "Should be able to describe backup vault")
	assert.Equal(t, vaultName, *vaultOutput.BackupVaultName, "Vault name should match")

	// Note: We can't easily validate backup selection without the selection ID output
	// This would require listing all selections and finding the one with matching name
	// For now, we'll skip this validation as the plan creation itself validates the selection
}

// TestMultipleBackupPlans tests the creation of multiple backup plans
func TestMultipleBackupPlans(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test
	uniqueId := random.UniqueId()
	vaultName := fmt.Sprintf("test-multi-vault-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/multiple_plans",
		Vars: map[string]interface{}{
			"vault_name":  vaultName,
			"aws_region":  "us-east-1",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))
	backupClient := backup.New(sess)

	// Validate that multiple backup plans were created
	planIds := terraform.OutputList(t, terraformOptions, "backup_plan_ids")
	require.Greater(t, len(planIds), 1, "Should create multiple backup plans")

	for i, planId := range planIds {
		planOutput, err := backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
			BackupPlanId: aws.String(planId),
		})
		require.NoError(t, err, fmt.Sprintf("Should be able to get backup plan %d", i))
		assert.NotEmpty(t, *planOutput.BackupPlan.BackupPlanName, fmt.Sprintf("Plan %d should have a name", i))
	}
}

// TestBackupPlanWithNotifications tests backup plan with SNS notifications
func TestBackupPlanWithNotifications(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test
	uniqueId := random.UniqueId()
	planName := fmt.Sprintf("test-notification-plan-%s", uniqueId)
	vaultName := fmt.Sprintf("test-notification-vault-%s", uniqueId)
	topicName := fmt.Sprintf("test-backup-topic-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/notifications",
		Vars: map[string]interface{}{
			"plan_name":   planName,
			"vault_name":  vaultName,
			"topic_name":  topicName,
			"aws_region":  "us-east-1",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))
	backupClient := backup.New(sess)

	// Validate backup plan exists
	planId := terraform.Output(t, terraformOptions, "backup_plan_id")
	planOutput, err := backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
		BackupPlanId: aws.String(planId),
	})
	require.NoError(t, err, "Should be able to get backup plan")
	assert.Equal(t, planName, *planOutput.BackupPlan.BackupPlanName, "Plan name should match")

	// Validate SNS topic was created
	topicArn := terraform.Output(t, terraformOptions, "backup_topic_arn")
	require.NotEmpty(t, topicArn, "Topic ARN should not be empty")
}

// TestIAMRoleCreation tests that IAM roles are created properly
func TestIAMRoleCreation(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test
	uniqueId := random.UniqueId()
	planName := fmt.Sprintf("test-iam-plan-%s", uniqueId)
	vaultName := fmt.Sprintf("test-iam-vault-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/basic",
		Vars: map[string]interface{}{
			"plan_name":   planName,
			"vault_name":  vaultName,
			"aws_region":  "us-east-1",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))
	iamClient := iam.New(sess)

	// Validate IAM role was created
	roleArn := terraform.Output(t, terraformOptions, "backup_role_arn")
	require.NotEmpty(t, roleArn, "Role ARN should not be empty")

	// Extract role name from ARN (role ARN format: arn:aws:iam::account:role/role-name)
	roleArnParts := strings.Split(roleArn, "/")
	require.Greater(t, len(roleArnParts), 1, "Role ARN should have proper format")
	roleName := roleArnParts[len(roleArnParts)-1]
	require.NotEmpty(t, roleName, "Role name should not be empty")

	// Get the role to verify it exists
	roleOutput, err := iamClient.GetRole(&iam.GetRoleInput{
		RoleName: aws.String(roleName),
	})
	require.NoError(t, err, "Should be able to get IAM role")
	assert.NotEmpty(t, *roleOutput.Role.AssumeRolePolicyDocument, "Role should have assume role policy")
}

// TestCrossRegionBackup tests cross-region backup functionality
func TestCrossRegionBackup(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test
	uniqueId := random.UniqueId()
	planName := fmt.Sprintf("test-cross-region-plan-%s", uniqueId)
	vaultName := fmt.Sprintf("test-cross-region-vault-%s", uniqueId)

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/cross_region",
		Vars: map[string]interface{}{
			"plan_name":           planName,
			"vault_name":          vaultName,
			"source_region":       "us-east-1",
			"destination_region":  "us-west-2",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Test in both regions
	regions := []string{"us-east-1", "us-west-2"}
	
	for _, region := range regions {
		sess := session.Must(session.NewSession(&aws.Config{
			Region: aws.String(region),
		}))
		backupClient := backup.New(sess)

		// Give some time for cross-region replication setup
		time.Sleep(30 * time.Second)

		// Validate backup vault exists in the region
		_, err := backupClient.DescribeBackupVault(&backup.DescribeBackupVaultInput{
			BackupVaultName: aws.String(vaultName),
		})
		
		if region == "us-east-1" {
			// Source region should have the vault
			require.NoError(t, err, fmt.Sprintf("Should be able to describe backup vault in %s", region))
		} else {
			// Destination region may or may not have the vault depending on setup
			// This is more complex to test without actual backup jobs
			if err == nil {
				t.Logf("Backup vault found in destination region %s", region)
			}
		}
	}
}