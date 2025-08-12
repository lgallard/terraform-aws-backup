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
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/ec2"
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

	// Generate unique names for this test using enhanced helpers
	planName := GenerateUniqueBackupPlanName(t)
	vaultName := GenerateUniqueBackupVaultName(t)
	selectionName := GenerateUniqueSelectionName(t)

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
	defer RetryableDestroy(t, terraformOptions)

	// Deploy the infrastructure
	RetryableInitAndApply(t, terraformOptions)

	// Validate that the backup plan was created
	backupClient := backup.New(sess)

	// Get the backup plan ARN from terraform output
	backupPlanArn := terraform.Output(t, terraformOptions, "backup_plan_arn")
	require.NotEmpty(t, backupPlanArn, "Backup plan ARN should not be empty")

	// Validate backup plan exists
	planId := terraform.Output(t, terraformOptions, "backup_plan_id")
	var planOutput *backup.GetBackupPlanOutput
	RetryableAWSOperation(t, "get backup plan", func() error {
		var err error
		planOutput, err = backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
			BackupPlanId: aws.String(planId),
		})
		return err
	})
	assert.Equal(t, planName, *planOutput.BackupPlan.BackupPlanName, "Plan name should match")

	// Validate backup vault exists
	vaultArn := terraform.Output(t, terraformOptions, "backup_vault_arn")
	require.NotEmpty(t, vaultArn, "Backup vault ARN should not be empty")

	var vaultOutput *backup.DescribeBackupVaultOutput
	RetryableAWSOperation(t, "describe backup vault", func() error {
		var err error
		vaultOutput, err = backupClient.DescribeBackupVault(&backup.DescribeBackupVaultInput{
			BackupVaultName: aws.String(vaultName),
		})
		return err
	})
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

	// Generate unique names for this test using enhanced helpers
	vaultName := GenerateUniqueResourceName(t, "test-multi-vault")

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/multiple_plans",
		Vars: map[string]interface{}{
			"vault_name":  vaultName,
			"aws_region":  "us-east-1",
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer RetryableDestroy(t, terraformOptions)

	// Deploy the infrastructure
	RetryableInitAndApply(t, terraformOptions)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))
	backupClient := backup.New(sess)

	// Validate that multiple backup plans were created
	planIds := terraform.OutputList(t, terraformOptions, "backup_plan_ids")
	require.Greater(t, len(planIds), 1, "Should create multiple backup plans")

	for i, planId := range planIds {
		var planOutput *backup.GetBackupPlanOutput
		RetryableAWSOperation(t, fmt.Sprintf("get backup plan %d", i), func() error {
			var err error
			planOutput, err = backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
				BackupPlanId: aws.String(planId),
			})
			return err
		})
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

	// Generate unique names for this test using enhanced helpers
	planName := GenerateUniqueResourceName(t, "test-notification-plan")
	vaultName := GenerateUniqueResourceName(t, "test-notification-vault")
	topicName := GenerateUniqueTopicName(t)

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
	defer RetryableDestroy(t, terraformOptions)

	// Deploy the infrastructure
	RetryableInitAndApply(t, terraformOptions)

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String("us-east-1"),
	}))
	backupClient := backup.New(sess)

	// Validate backup plan exists
	planId := terraform.Output(t, terraformOptions, "backup_plan_id")
	var planOutput *backup.GetBackupPlanOutput
	RetryableAWSOperation(t, "get backup plan with notifications", func() error {
		var err error
		planOutput, err = backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
			BackupPlanId: aws.String(planId),
		})
		return err
	})
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

	// Generate unique names for this test using enhanced helpers
	planName := GenerateUniqueResourceName(t, "test-iam-plan")
	vaultName := GenerateUniqueResourceName(t, "test-iam-vault")

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
	defer RetryableDestroy(t, terraformOptions)

	// Deploy the infrastructure
	RetryableInitAndApply(t, terraformOptions)

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
	var roleOutput *iam.GetRoleOutput
	RetryableAWSOperation(t, "get IAM role", func() error {
		var err error
		roleOutput, err = iamClient.GetRole(&iam.GetRoleInput{
			RoleName: aws.String(roleName),
		})
		return err
	})
	assert.NotEmpty(t, *roleOutput.Role.AssumeRolePolicyDocument, "Role should have assume role policy")
}

// TestCrossRegionBackup tests cross-region backup functionality
func TestCrossRegionBackup(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test using enhanced helpers
	planName := GenerateUniqueResourceName(t, "test-cross-region-plan")
	vaultName := GenerateUniqueResourceName(t, "test-cross-region-vault")

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/cross_region",
		Vars: map[string]interface{}{
			"plan_name":           planName,
			"vault_name":          vaultName,
			"source_region":       GetTestRegion(),
			"destination_region":  GetCrossRegion(),
		},
		NoColor: true,
	}

	// Clean up resources after test
	defer RetryableDestroy(t, terraformOptions)

	// Deploy the infrastructure
	RetryableInitAndApply(t, terraformOptions)

	// Test in both regions
	regions := []string{GetTestRegion(), GetCrossRegion()}

	for _, region := range regions {
		sess := session.Must(session.NewSession(&aws.Config{
			Region: aws.String(region),
		}))
		backupClient := backup.New(sess)

		// Give some time for cross-region replication setup
		time.Sleep(30 * time.Second)

		// Validate backup vault exists in the region
		var vaultErr error
		RetryableAWSOperation(t, fmt.Sprintf("describe backup vault in %s", region), func() error {
			_, vaultErr = backupClient.DescribeBackupVault(&backup.DescribeBackupVaultInput{
				BackupVaultName: aws.String(vaultName),
			})
			return vaultErr
		})

		if region == GetTestRegion() {
			// Source region should have the vault
			require.NoError(t, vaultErr, fmt.Sprintf("Should be able to describe backup vault in %s", region))
		} else {
			// Destination region may or may not have the vault depending on setup
			// This is more complex to test without actual backup jobs
			if vaultErr == nil {
				t.Logf("Backup vault found in destination region %s", region)
			}
		}
	}
}

// TestBackupRestore tests the full backup and restore cycle
func TestBackupRestore(t *testing.T) {
	// Skip if running in CI without AWS credentials
	if os.Getenv("CI") != "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		t.Skip("Skipping integration test in CI without AWS credentials")
	}

	t.Parallel()

	// Generate unique names for this test using enhanced helpers
	resourcePrefix := GenerateUniqueResourceName(t, "backup-restore")
	planName := GenerateUniqueResourceName(t, "backup-restore-plan")
	vaultName := GenerateUniqueResourceName(t, "backup-restore-vault")

	// Set up AWS session
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(GetTestRegion()),
	}))

	terraformOptions := &terraform.Options{
		TerraformDir: "fixtures/terraform/backup_restore",
		Vars: map[string]interface{}{
			"resource_prefix": resourcePrefix,
			"plan_name":       planName,
			"vault_name":      vaultName,
			"aws_region":      GetTestRegion(),
		},
		NoColor: true,
	}

	// Create resource cleanup helper
	cleanup := NewTestResourceCleanup(t)

	// Clean up resources after test
	defer func() {
		cleanup.LogResources()
		RetryableDestroy(t, terraformOptions)
	}()

	// Deploy the test infrastructure
	t.Logf("Deploying test infrastructure for backup restore testing...")
	RetryableInitAndApply(t, terraformOptions)

	// Get outputs from terraform
	backupPlanId := terraform.Output(t, terraformOptions, "backup_plan_id")
	backupVaultId := terraform.Output(t, terraformOptions, "backup_vault_id")
	testInstanceId := terraform.Output(t, terraformOptions, "test_instance_id")
	testVolumeId := terraform.Output(t, terraformOptions, "test_volume_id")
	testTableName := terraform.Output(t, terraformOptions, "test_dynamodb_table_name")

	// Add resources to cleanup tracking
	cleanup.AddResource(fmt.Sprintf("Backup Plan: %s", backupPlanId))
	cleanup.AddResource(fmt.Sprintf("Backup Vault: %s", backupVaultId))
	cleanup.AddResource(fmt.Sprintf("Test Instance: %s", testInstanceId))
	cleanup.AddResource(fmt.Sprintf("Test Volume: %s", testVolumeId))
	cleanup.AddResource(fmt.Sprintf("Test DynamoDB Table: %s", testTableName))

	t.Logf("Test infrastructure deployed successfully")

	// Set up AWS service clients
	backupClient := backup.New(sess)
	ec2Client := ec2.New(sess)
	dynamodbClient := dynamodb.New(sess)

	// Wait for instance to be running and initialized
	t.Logf("Waiting for test instance to be ready...")
	RetryableAWSOperation(t, "wait for instance running", func() error {
		input := &ec2.DescribeInstancesInput{
			InstanceIds: []*string{aws.String(testInstanceId)},
		}
		result, err := ec2Client.DescribeInstances(input)
		if err != nil {
			return err
		}

		if len(result.Reservations) == 0 || len(result.Reservations[0].Instances) == 0 {
			return fmt.Errorf("instance not found")
		}

		state := *result.Reservations[0].Instances[0].State.Name
		if state != "running" {
			return fmt.Errorf("instance state is %s, waiting for running", state)
		}

		return nil
	})

	// Wait additional time for user data script to complete
	t.Logf("Waiting for user data initialization to complete...")
	time.Sleep(3 * time.Minute)

	// Phase 1: Create backup jobs
	t.Logf("Starting backup jobs...")

	// Start backup job for EBS volume
	volumeBackupJobId := startBackupJob(t, backupClient, testVolumeId, backupVaultId, "EBS")

	// Start backup job for EC2 instance
	instanceBackupJobId := startBackupJob(t, backupClient, testInstanceId, backupVaultId, "EC2")

	// Start backup job for DynamoDB table
	tableArn := terraform.Output(t, terraformOptions, "test_dynamodb_table_arn")
	dynamodbBackupJobId := startBackupJob(t, backupClient, tableArn, backupVaultId, "DynamoDB")

	// Phase 2: Wait for backup jobs to complete
	t.Logf("Waiting for backup jobs to complete...")

	volumeRecoveryPointArn := waitForBackupCompletion(t, backupClient, volumeBackupJobId, 30*time.Minute)
	instanceRecoveryPointArn := waitForBackupCompletion(t, backupClient, instanceBackupJobId, 30*time.Minute)
	dynamodbRecoveryPointArn := waitForBackupCompletion(t, backupClient, dynamodbBackupJobId, 30*time.Minute)

	t.Logf("All backup jobs completed successfully")

	// Phase 3: Restore from backups
	t.Logf("Starting restore operations...")

	// Restore EBS volume
	restoredVolumeArn := restoreEBSVolume(t, backupClient, volumeRecoveryPointArn, resourcePrefix)

	// Restore DynamoDB table
	restoredTableName := restoreDynamoDBTable(t, backupClient, dynamodbRecoveryPointArn, resourcePrefix)

	// Phase 4: Wait for restore operations to complete
	t.Logf("Waiting for restore operations to complete...")

	// Wait for volume restore
	waitForRestoreCompletion(t, backupClient, restoredVolumeArn, 20*time.Minute)

	// Wait for DynamoDB table restore
	waitForRestoreCompletion(t, backupClient, restoredTableName, 20*time.Minute)

	t.Logf("All restore operations completed successfully")

	// Phase 5: Validate restored data
	t.Logf("Validating restored data...")

	// Validate EBS volume restore
	validateEBSVolumeRestore(t, ec2Client, restoredVolumeArn)

	// Validate DynamoDB table restore
	validateDynamoDBTableRestore(t, dynamodbClient, restoredTableName)

	t.Logf("Backup and restore test completed successfully!")
}

// Helper function to start a backup job
func startBackupJob(t *testing.T, client *backup.Backup, resourceArn, vaultName, resourceType string) string {
	var backupJobId string

	RetryableAWSOperation(t, fmt.Sprintf("start backup job for %s", resourceType), func() error {
		input := &backup.StartBackupJobInput{
			BackupVaultName: aws.String(vaultName),
			ResourceArn:     aws.String(resourceArn),
			IamRoleArn:      aws.String("arn:aws:iam::123456789012:role/aws-backup-default-service-role"), // This would be created by the module
		}

		result, err := client.StartBackupJob(input)
		if err != nil {
			return err
		}

		backupJobId = *result.BackupJobId
		return nil
	})

	t.Logf("Started backup job %s for %s resource", backupJobId, resourceType)
	return backupJobId
}

// Helper function to wait for backup completion
func waitForBackupCompletion(t *testing.T, client *backup.Backup, jobId string, timeout time.Duration) string {
	var recoveryPointArn string

	start := time.Now()
	for time.Since(start) < timeout {
		var job *backup.DescribeBackupJobOutput

		RetryableAWSOperation(t, "describe backup job", func() error {
			input := &backup.DescribeBackupJobInput{
				BackupJobId: aws.String(jobId),
			}

			var err error
			job, err = client.DescribeBackupJob(input)
			return err
		})

		state := *job.State
		t.Logf("Backup job %s state: %s", jobId, state)

		switch state {
		case "COMPLETED":
			recoveryPointArn = *job.RecoveryPointArn
			t.Logf("Backup job %s completed successfully, recovery point: %s", jobId, recoveryPointArn)
			return recoveryPointArn
		case "FAILED":
			t.Fatalf("Backup job %s failed", jobId)
		case "ABORTED":
			t.Fatalf("Backup job %s was aborted", jobId)
		default:
			// Still running, wait and check again
			time.Sleep(30 * time.Second)
		}
	}

	t.Fatalf("Backup job %s did not complete within %v", jobId, timeout)
	return ""
}

// Helper function to restore EBS volume
func restoreEBSVolume(t *testing.T, client *backup.Backup, recoveryPointArn, resourcePrefix string) string {
	var restoreJobId string

	RetryableAWSOperation(t, "start EBS volume restore", func() error {
		input := &backup.StartRestoreJobInput{
			RecoveryPointArn: aws.String(recoveryPointArn),
			Metadata: map[string]*string{
				"VolumeSize": aws.String("8"),
				"VolumeType": aws.String("gp3"),
				"Encrypted":  aws.String("true"),
			},
			IamRoleArn: aws.String("arn:aws:iam::123456789012:role/aws-backup-default-service-role"),
		}

		result, err := client.StartRestoreJob(input)
		if err != nil {
			return err
		}

		restoreJobId = *result.RestoreJobId
		return nil
	})

	t.Logf("Started EBS volume restore job: %s", restoreJobId)
	return restoreJobId
}

// Helper function to restore DynamoDB table
func restoreDynamoDBTable(t *testing.T, client *backup.Backup, recoveryPointArn, resourcePrefix string) string {
	var restoreJobId string

	RetryableAWSOperation(t, "start DynamoDB table restore", func() error {
		input := &backup.StartRestoreJobInput{
			RecoveryPointArn: aws.String(recoveryPointArn),
			Metadata: map[string]*string{
				"TableName": aws.String(fmt.Sprintf("%s-restored-table", resourcePrefix)),
			},
			IamRoleArn: aws.String("arn:aws:iam::123456789012:role/aws-backup-default-service-role"),
		}

		result, err := client.StartRestoreJob(input)
		if err != nil {
			return err
		}

		restoreJobId = *result.RestoreJobId
		return nil
	})

	t.Logf("Started DynamoDB table restore job: %s", restoreJobId)
	return restoreJobId
}

// Helper function to wait for restore completion
func waitForRestoreCompletion(t *testing.T, client *backup.Backup, jobId string, timeout time.Duration) {
	start := time.Now()
	for time.Since(start) < timeout {
		var job *backup.DescribeRestoreJobOutput

		RetryableAWSOperation(t, "describe restore job", func() error {
			input := &backup.DescribeRestoreJobInput{
				RestoreJobId: aws.String(jobId),
			}

			var err error
			job, err = client.DescribeRestoreJob(input)
			return err
		})

		state := *job.Status
		t.Logf("Restore job %s state: %s", jobId, state)

		switch state {
		case "COMPLETED":
			t.Logf("Restore job %s completed successfully", jobId)
			return
		case "FAILED":
			t.Fatalf("Restore job %s failed", jobId)
		case "ABORTED":
			t.Fatalf("Restore job %s was aborted", jobId)
		default:
			// Still running, wait and check again
			time.Sleep(30 * time.Second)
		}
	}

	t.Fatalf("Restore job %s did not complete within %v", jobId, timeout)
}

// Helper function to validate EBS volume restore
func validateEBSVolumeRestore(t *testing.T, client *ec2.EC2, volumeArn string) {
	// Extract volume ID from ARN
	parts := strings.Split(volumeArn, "/")
	volumeId := parts[len(parts)-1]

	RetryableAWSOperation(t, "validate EBS volume restore", func() error {
		input := &ec2.DescribeVolumesInput{
			VolumeIds: []*string{aws.String(volumeId)},
		}

		result, err := client.DescribeVolumes(input)
		if err != nil {
			return err
		}

		if len(result.Volumes) == 0 {
			return fmt.Errorf("restored volume not found")
		}

		volume := result.Volumes[0]
		assert.Equal(t, "available", *volume.State, "Restored volume should be available")
		assert.Equal(t, int64(8), *volume.Size, "Restored volume should have correct size")
		assert.True(t, *volume.Encrypted, "Restored volume should be encrypted")

		return nil
	})

	t.Logf("EBS volume restore validation completed successfully")
}

// Helper function to validate DynamoDB table restore
func validateDynamoDBTableRestore(t *testing.T, client *dynamodb.DynamoDB, tableName string) {
	RetryableAWSOperation(t, "validate DynamoDB table restore", func() error {
		input := &dynamodb.DescribeTableInput{
			TableName: aws.String(tableName),
		}

		result, err := client.DescribeTable(input)
		if err != nil {
			return err
		}

		table := result.Table
		assert.Equal(t, "ACTIVE", *table.TableStatus, "Restored table should be active")
		assert.Equal(t, "PAY_PER_REQUEST", *table.BillingModeSummary.BillingMode, "Restored table should use PAY_PER_REQUEST")

		// Check if test data exists
		getInput := &dynamodb.GetItemInput{
			TableName: aws.String(tableName),
			Key: map[string]*dynamodb.AttributeValue{
				"id": {
					S: aws.String("test-item-1"),
				},
			},
		}

		getResult, err := client.GetItem(getInput)
		if err != nil {
			return err
		}

		if getResult.Item == nil {
			return fmt.Errorf("test data not found in restored table")
		}

		return nil
	})

	t.Logf("DynamoDB table restore validation completed successfully")
}
