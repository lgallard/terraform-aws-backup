# AWS Backup Restore Testing Plan Example

This example demonstrates how to configure AWS Backup restore testing to automatically validate backup recovery points on a schedule.

## Features Demonstrated

- **Backup Configuration**: Creates a daily backup plan for EC2 instances
- **Restore Testing Plan**: Configures weekly automated restore testing
- **Restore Testing Selection**: Defines which resources to test restoration for
- **IAM Integration**: Automatically creates necessary IAM roles and policies
- **Cost Optimization**: Uses smaller instance types for testing to minimize costs
- **Compliance**: Helps meet regulatory requirements for backup validation

## Architecture

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Source EC2        │    │   Backup Vault      │    │   Test Environment  │
│   Instance          │───▶│   - Daily Backups   │───▶│   - Restore Testing │
│   (Production)      │    │   - Recovery Points │    │   - Validation      │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
                                      │
                                      ▼
                           ┌─────────────────────┐
                           │   Restore Testing   │
                           │   - Weekly Schedule │
                           │   - Automated Tests │
                           │   - CloudWatch Logs │
                           └─────────────────────┘
```

## What This Example Creates

### Backup Resources
- **Backup Vault**: Stores recovery points securely
- **Backup Plan**: Daily backup schedule at 2 AM UTC
- **Backup Selection**: Targets EC2 instances with specific tags
- **Lifecycle Policy**: Moves to cold storage after 30 days, deletes after 90 days

### Restore Testing Resources
- **Restore Testing Plan**: Weekly testing schedule (Sundays at 6 AM UTC)
- **Restore Testing Selection**: Tests EC2 instances with `BackupPlan=daily` tag
- **IAM Role**: Least-privilege permissions for restore operations
- **Test Configuration**: Uses `t3.nano` instances to minimize testing costs

### Test Instance
- **EC2 Instance**: Sample instance to backup and test restoration
- **Security Group**: Minimal security group for the test instance
- **Tags**: Properly tagged for backup selection and testing

## Usage

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- AWS provider >= 5.0

### Deploy the Example

```bash
# Clone the repository and navigate to this example
cd examples/restore_testing_plan

# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply
```

### Verify the Setup

```bash
# List restore testing plans
aws backup list-restore-testing-plans

# Describe the created plan
aws backup describe-restore-testing-plan --restore-testing-plan-name <plan-name>

# List selections for the plan
aws backup list-restore-testing-selections --restore-testing-plan-name <plan-name>

# Check recent backup jobs
aws backup list-backup-jobs --by-resource-arn <instance-arn>
```

### Monitor Restore Testing

1. **AWS Console**: Navigate to AWS Backup → Restore testing to monitor test executions
2. **CloudWatch Logs**: Review detailed logs at `/aws/backup/restore-testing`
3. **CloudWatch Metrics**: Monitor restore test success/failure rates
4. **SNS Notifications**: Set up alerts for test completion (optional)

## Configuration Details

### Backup Schedule
- **Frequency**: Daily at 2 AM UTC
- **Window**: 1-hour start window, 5-hour completion window
- **Retention**: 30 days standard, 90 days total lifecycle

### Restore Testing Schedule
- **Frequency**: Weekly on Sundays at 6 AM UTC
- **Window**: 2-hour start window for testing
- **Validation**: 24-hour window to validate restored resources
- **Algorithm**: Tests latest recovery points within 7-day window

### Cost Optimization
- **Test Instance Type**: Uses `t3.nano` instead of original instance size
- **Validation Window**: 24 hours to minimize resource running time
- **Automatic Cleanup**: Test resources are automatically cleaned up

## Security Considerations

### IAM Permissions
- **Least Privilege**: IAM role has minimal required permissions
- **Service Principal**: Uses `backup.amazonaws.com` service principal
- **Resource Restrictions**: Limited to backup-related resources and operations

### Network Security
- **Security Group**: Minimal outbound-only security group for test instance
- **VPC**: Uses default VPC for simplicity (customize as needed)

### Encryption
- **Backup Encryption**: Uses AWS managed keys (can be customized)
- **Transit Encryption**: All API calls use HTTPS

## Compliance Benefits

### Regulatory Requirements
- **SOC 2**: Demonstrates backup recovery validation
- **ISO 27001**: Provides evidence of backup effectiveness
- **HIPAA**: Ensures backup integrity for sensitive data
- **PCI DSS**: Validates backup recovery procedures

### Audit Trail
- **CloudWatch Logs**: Detailed restore test execution logs
- **CloudTrail**: API call history for all backup operations
- **Test Results**: Automated validation of restore success/failure

## Customization Options

### Modify Testing Frequency
```hcl
restore_testing_plans = {
  daily_restore_test = {
    schedule_expression = "cron(0 6 ? * * *)" # Daily instead of weekly
    # ... other configuration
  }
}
```

### Add Multiple Resource Types
```hcl
restore_testing_selections = {
  ec2_selection = {
    protected_resource_type = "EC2"
    # ... configuration
  }
  rds_selection = {
    protected_resource_type = "RDS"
    # ... configuration
  }
}
```

### Custom IAM Role
```hcl
module "aws_backup" {
  # ... other configuration
  restore_testing_iam_role_arn = aws_iam_role.custom_restore_role.arn
}
```

## Troubleshooting

### Common Issues

1. **IAM Permissions**: Ensure the restore testing role has necessary permissions
2. **Resource Tags**: Verify EC2 instances have correct tags for selection
3. **Backup Completion**: Ensure backups complete before testing starts
4. **Network Access**: Check security groups allow necessary traffic

### Useful Commands
```bash
# Check backup job status
aws backup describe-backup-job --backup-job-id <job-id>

# List recent restore jobs
aws backup list-restore-jobs --by-creation-date-after 2024-01-01T00:00:00Z

# Describe restore testing selection
aws backup describe-restore-testing-selection \
  --restore-testing-plan-name <plan-name> \
  --restore-testing-selection-name <selection-name>

# Start manual restore test
aws backup start-restore-testing-job \
  --restore-testing-plan-name <plan-name>
```

## Cost Estimation

### Monthly Costs (approximate)
- **Backup Storage**: ~$0.05 per GB per month
- **Restore Testing**: ~$0.02 per test execution (t3.nano for 24 hours)
- **Data Transfer**: Minimal for same-region restore testing
- **CloudWatch Logs**: ~$0.50 per GB ingested

### Cost Optimization Tips
1. **Lifecycle Policies**: Move old backups to cold storage
2. **Test Instance Sizing**: Use smallest viable instance types
3. **Testing Frequency**: Balance compliance needs with costs
4. **Regional Strategy**: Keep testing in same region as backups

## Next Steps

1. **Customize for Your Environment**: Modify tags, schedules, and resource types
2. **Add Notifications**: Set up SNS topics for test results
3. **Expand Coverage**: Add more resource types and backup plans
4. **Monitor Costs**: Set up billing alerts for backup and testing costs
5. **Integrate with CI/CD**: Automate deployment of backup configurations

## Support

For questions or issues:
- Review the [main module documentation](../../README.md)
- Check [AWS Backup documentation](https://docs.aws.amazon.com/backup/)
- Open an issue in the [GitHub repository](https://github.com/lgallard/terraform-aws-backup/issues)

## License

This example is provided under the same license as the main module.
