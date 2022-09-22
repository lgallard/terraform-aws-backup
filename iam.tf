data "aws_partition" "current" {}

data "aws_iam_policy_document" "ab_role_assume_role_policy" {
  count = var.enabled && var.iam_role_arn == null ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ab_role" {
  count              = var.enabled && var.iam_role_arn == null ? 1 : 0
  name               = var.iam_role_name == "" ? "aws-backup-plan-${var.plan_name}-role" : var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ab_role_assume_role_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ab_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.ab_role[0].name
}

resource "aws_iam_role_policy_attachment" "ab_backup_s3_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.ab_role[0].name
}

# Tag policy
data "aws_iam_policy_document" "ab_tag_policy_document" {
  count = var.enabled && var.iam_role_arn == null ? 1 : 0
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "backup:TagResource",
      "backup:ListTags",
      "backup:UntagResource",
      "tag:GetResources"
    ]
  }
}

resource "aws_iam_policy" "ab_tag_policy" {
  count       = var.enabled && var.iam_role_arn == null ? 1 : 0
  description = "AWS Backup Tag policy"
  policy      = data.aws_iam_policy_document.ab_tag_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "ab_tag_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = aws_iam_policy.ab_tag_policy[0].arn
  role       = aws_iam_role.ab_role[0].name
}

# Restores policy
resource "aws_iam_role_policy_attachment" "ab_restores_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.ab_role[0].name
}

resource "aws_iam_role_policy_attachment" "ab_restores_s3_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.ab_role[0].name
}
