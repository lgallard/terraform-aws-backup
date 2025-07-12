data "aws_partition" "current" {}

# Optimized locals for IAM resource management
locals {
  create_iam_resources = var.enabled && var.iam_role_arn == null

  # Pre-compute managed policy ARNs for batch processing
  backup_managed_policy_arns = local.create_iam_resources ? toset([
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  ]) : toset([])
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
