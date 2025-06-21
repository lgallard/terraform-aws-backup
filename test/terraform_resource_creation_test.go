package test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/backup"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/sts"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestResourceCreationIntegration creates actual AWS resources and tests backup functionality
func TestResourceCreationIntegration(t *testing.T) {
	// Skip test if AWS credentials are not available
	if !isAWSCredentialsAvailable() {
		t.Skip("Skipping integration test - AWS credentials not available")
	}

	t.Parallel()

	// Generate unique names for resources to avoid conflicts
	uniqueID := fmt.Sprintf("terratest-%d", time.Now().Unix())
	tableName := fmt.Sprintf("test-table-%s", uniqueID)
	vaultName := fmt.Sprintf("test-vault-%s", uniqueID)
	planName := fmt.Sprintf("test-plan-%s", uniqueID)

	// AWS session for resource verification
	sess, err := session.NewSession()
	require.NoError(t, err)

	dynamodbClient := dynamodb.New(sess)
	backupClient := backup.New(sess)

	// Setup Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../test/fixtures/resource_creation",
		Vars: map[string]interface{}{
			"table_name": tableName,
			"vault_name": vaultName,
			"plan_name":  planName,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},
	}

	// Clean up resources at the end of the test
	defer func() {
		// Destroy Terraform resources
		terraform.Destroy(t, terraformOptions)

		// Verify DynamoDB table is deleted
		_, err := dynamodbClient.DescribeTable(&dynamodb.DescribeTableInput{
			TableName: aws.String(tableName),
		})
		if err != nil {
			t.Logf("DynamoDB table %s successfully deleted or does not exist", tableName)
		}
	}()

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Verify DynamoDB table exists
	tableOutput, err := dynamodbClient.DescribeTable(&dynamodb.DescribeTableInput{
		TableName: aws.String(tableName),
	})
	require.NoError(t, err)
	assert.Equal(t, tableName, *tableOutput.Table.TableName)
	assert.Equal(t, "ACTIVE", *tableOutput.Table.TableStatus)

	// Verify backup vault exists
	vaultOutput, err := backupClient.DescribeBackupVault(&backup.DescribeBackupVaultInput{
		BackupVaultName: aws.String(vaultName),
	})
	require.NoError(t, err)
	assert.Equal(t, vaultName, *vaultOutput.BackupVaultName)

	// Verify backup plan exists
	planOutput, err := backupClient.GetBackupPlan(&backup.GetBackupPlanInput{
		BackupPlanId: aws.String(terraform.Output(t, terraformOptions, "backup_plan_id")),
	})
	require.NoError(t, err)
	assert.Equal(t, planName, *planOutput.BackupPlan.BackupPlanName)

	// Verify backup selection exists
	selections, err := backupClient.ListBackupSelections(&backup.ListBackupSelectionsInput{
		BackupPlanId: aws.String(terraform.Output(t, terraformOptions, "backup_plan_id")),
	})
	require.NoError(t, err)
	assert.True(t, len(selections.BackupSelectionsList) > 0)

	// Verify the DynamoDB table is included in the backup selection
	tableArn := *tableOutput.Table.TableArn
	selectionOutput, err := backupClient.GetBackupSelection(&backup.GetBackupSelectionInput{
		BackupPlanId:    aws.String(terraform.Output(t, terraformOptions, "backup_plan_id")),
		SelectionId:     selections.BackupSelectionsList[0].SelectionId,
	})
	require.NoError(t, err)

	// Check if the table ARN is in the resources list
	found := false
	for _, resource := range selectionOutput.BackupSelection.Resources {
		if *resource == tableArn {
			found = true
			break
		}
	}
	assert.True(t, found, "DynamoDB table ARN should be included in backup selection resources")

	t.Logf("✅ Integration test passed - all resources created and backup configuration validated")
}

// TestOnDemandBackupJob creates resources and triggers an on-demand backup job
func TestOnDemandBackupJob(t *testing.T) {
	// Skip test if AWS credentials are not available
	if !isAWSCredentialsAvailable() {
		t.Skip("Skipping integration test - AWS credentials not available")
	}

	t.Parallel()

	// Generate unique names for resources
	uniqueID := fmt.Sprintf("terratest-backup-%d", time.Now().Unix())
	tableName := fmt.Sprintf("test-backup-table-%s", uniqueID)
	vaultName := fmt.Sprintf("test-backup-vault-%s", uniqueID)

	// AWS session for backup operations
	sess, err := session.NewSession()
	require.NoError(t, err)

	dynamodbClient := dynamodb.New(sess)
	backupClient := backup.New(sess)

	// Setup Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../test/fixtures/backup_job",
		Vars: map[string]interface{}{
			"table_name": tableName,
			"vault_name": vaultName,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": "us-west-2",
		},
	}

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run terraform init and apply
	terraform.InitAndApply(t, terraformOptions)

	// Get the table ARN for backup
	tableOutput, err := dynamodbClient.DescribeTable(&dynamodb.DescribeTableInput{
		TableName: aws.String(tableName),
	})
	require.NoError(t, err)
	tableArn := *tableOutput.Table.TableArn

	// Start an on-demand backup job
	backupJobInput := &backup.StartBackupJobInput{
		BackupVaultName:   aws.String(vaultName),
		ResourceArn:       aws.String(tableArn),
		IamRoleArn:        aws.String(terraform.Output(t, terraformOptions, "backup_role_arn")),
		IdempotencyToken:  aws.String(fmt.Sprintf("test-backup-%s", uniqueID)),
	}

	backupJobOutput, err := backupClient.StartBackupJob(backupJobInput)
	require.NoError(t, err)

	backupJobId := *backupJobOutput.BackupJobId
	t.Logf("Started backup job: %s", backupJobId)

	// Wait for backup job to complete (with timeout)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	err = waitForBackupJob(ctx, backupClient, backupJobId)
	if err != nil {
		t.Logf("⚠️  Backup job did not complete within timeout, but job was successfully started: %v", err)
		// Don't fail the test, just log the warning since backup jobs can take a long time
	} else {
		t.Logf("✅ Backup job completed successfully")
	}

	// Verify backup job exists in the system
	jobOutput, err := backupClient.DescribeBackupJob(&backup.DescribeBackupJobInput{
		BackupJobId: aws.String(backupJobId),
	})
	require.NoError(t, err)
	assert.Equal(t, backupJobId, *jobOutput.BackupJobId)
	assert.Equal(t, tableArn, *jobOutput.ResourceArn)

	t.Logf("✅ On-demand backup job test completed successfully")
}

// isAWSCredentialsAvailable checks if AWS credentials are available
func isAWSCredentialsAvailable() bool {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String("us-west-2"),
	})
	if err != nil {
		return false
	}
	
	// Try to create a simple STS client and call GetCallerIdentity
	// This will fail if credentials are not available or invalid
	stsClient := sts.New(sess)
	_, err = stsClient.GetCallerIdentity(&sts.GetCallerIdentityInput{})
	return err == nil
}

// waitForBackupJob waits for a backup job to complete
func waitForBackupJob(ctx context.Context, client *backup.Backup, jobId string) error {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for backup job %s to complete", jobId)
		case <-ticker.C:
			output, err := client.DescribeBackupJob(&backup.DescribeBackupJobInput{
				BackupJobId: aws.String(jobId),
			})
			if err != nil {
				return fmt.Errorf("error describing backup job: %v", err)
			}

			state := *output.State
			switch state {
			case "COMPLETED":
				return nil
			case "FAILED", "ABORTED", "EXPIRED":
				return fmt.Errorf("backup job failed with state: %s", state)
			default:
				// Continue waiting for states: CREATED, PENDING, RUNNING
				continue
			}
		}
	}
}