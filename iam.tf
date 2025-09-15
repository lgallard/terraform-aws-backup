data "aws_partition" "current" {}

# Optimized locals for IAM resource management
locals {
  create_iam_resources = var.enabled && var.iam_role_arn == null

  # Restore testing IAM resource creation condition
  create_restore_testing_iam_resources = var.enabled && var.restore_testing_iam_role_arn == null && length(var.restore_testing_selections) > 0

  # Pre-compute managed policy ARNs for batch processing
  backup_managed_policy_arns = local.create_iam_resources ? {
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"   = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"              = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores" = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"             = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  } : {}

  # Pre-compute restore testing managed policy ARNs
  restore_testing_managed_policy_arns = local.create_restore_testing_iam_resources ? {
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores" = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"             = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  } : {}
}

data "aws_iam_policy_document" "ab_role_assume_role_policy" {
  count = local.create_iam_resources ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ab_role" {
  count = local.create_iam_resources ? 1 : 0

  name               = coalesce(var.iam_role_name, "aws-backup-${var.vault_name != null ? var.vault_name : "default"}")
  assume_role_policy = data.aws_iam_policy_document.ab_role_assume_role_policy[0].json

  tags = var.tags
}

# Optimized: Batch managed policy attachments using for_each
resource "aws_iam_role_policy_attachment" "ab_managed_policies" {
  for_each = local.backup_managed_policy_arns

  policy_arn = each.value
  role       = aws_iam_role.ab_role[0].name
}

# Tag policy
data "aws_iam_policy_document" "ab_tag_policy_document" {
  count = local.create_iam_resources ? 1 : 0
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "backup:ListTags",
      "backup:TagResource",
      "backup:UntagResource",
      "tag:GetResources"
    ]
  }
}

resource "aws_iam_policy" "ab_tag_policy" {
  count       = local.create_iam_resources ? 1 : 0
  description = "AWS Backup Tag policy"
  policy      = data.aws_iam_policy_document.ab_tag_policy_document[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "ab_tag_policy_attach" {
  count      = local.create_iam_resources ? 1 : 0
  policy_arn = aws_iam_policy.ab_tag_policy[0].arn
  role       = aws_iam_role.ab_role[0].name
}

#
# AWS Backup Restore Testing IAM Resources
#

# Restore testing role assume role policy
data "aws_iam_policy_document" "restore_testing_assume_role_policy" {
  count = local.create_restore_testing_iam_resources ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

# Restore testing IAM role
resource "aws_iam_role" "restore_testing_role" {
  count = local.create_restore_testing_iam_resources ? 1 : 0

  name               = "aws-backup-restore-testing-role-${random_string.restore_testing_suffix[0].result}"
  assume_role_policy = data.aws_iam_policy_document.restore_testing_assume_role_policy[0].json

  tags = merge(
    var.tags,
    {
      Name        = "aws-backup-restore-testing-role"
      Description = "IAM role for AWS Backup restore testing operations"
    }
  )
}

# Random suffix for restore testing role name uniqueness
resource "random_string" "restore_testing_suffix" {
  count   = local.create_restore_testing_iam_resources ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# Attach managed policies for restore testing
resource "aws_iam_role_policy_attachment" "restore_testing_managed_policies" {
  for_each = local.restore_testing_managed_policy_arns

  policy_arn = each.value
  role       = aws_iam_role.restore_testing_role[0].name
}

# Restore testing custom policy for additional permissions
data "aws_iam_policy_document" "restore_testing_policy_document" {
  count = local.create_restore_testing_iam_resources ? 1 : 0

  # Basic restore testing permissions
  statement {
    effect = "Allow"
    actions = [
      "backup:StartRestoreJob",
      "backup:DescribeRestoreJob",
      "backup:ListRestoreJobs",
      "backup:StartRestoreTestingJob",
      "backup:DescribeRestoreTestingPlan",
      "backup:DescribeRestoreTestingSelection",
      "backup:ListRestoreTestingPlans",
      "backup:ListRestoreTestingSelections",
    ]
    resources = ["*"]
  }

  # IAM permissions for restore testing
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::*:role/aws-backup-*"
    ]
  }

  # CloudWatch permissions for monitoring
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:*:*:log-group:/aws/backup/*"
    ]
  }

  # EC2 permissions for EC2 restore testing
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }

  # RDS permissions for RDS restore testing
  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
      "rds:DescribeDBSnapshots",
      "rds:DescribeDBClusterSnapshots",
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBParameterGroups",
      "rds:DescribeDBClusterParameterGroups"
    ]
    resources = ["*"]
  }
}

# Restore testing custom policy
resource "aws_iam_policy" "restore_testing_policy" {
  count       = local.create_restore_testing_iam_resources ? 1 : 0
  name        = "aws-backup-restore-testing-policy-${random_string.restore_testing_suffix[0].result}"
  description = "Custom policy for AWS Backup restore testing operations"
  policy      = data.aws_iam_policy_document.restore_testing_policy_document[0].json
  tags        = var.tags
}

# Attach custom restore testing policy
resource "aws_iam_role_policy_attachment" "restore_testing_policy_attach" {
  count      = local.create_restore_testing_iam_resources ? 1 : 0
  policy_arn = aws_iam_policy.restore_testing_policy[0].arn
  role       = aws_iam_role.restore_testing_role[0].name
}
