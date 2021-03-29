resource "aws_iam_role" "ab_role" {
  count              = var.enabled && var.iam_role_arn == null ? 1 : 0
  name               = "aws-backup-plan-${var.plan_name}-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ab_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.ab_role[0].name
}

# Tag policy
resource "aws_iam_policy" "ab_tag_policy" {

  count       = var.enabled && var.iam_role_arn == null ? 1 : 0
  description = "AWS Backup Tag policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "backup:TagResource",
            "backup:ListTags",
            "backup:UntagResource",
            "tag:GetResources"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ab_tag_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = aws_iam_policy.ab_tag_policy[0].arn
  role       = aws_iam_role.ab_role[0].name
}


# Restores policy
resource "aws_iam_role_policy_attachment" "ab_restores_policy_attach" {
  count      = var.enabled && var.iam_role_arn == null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.ab_role[0].name
}
