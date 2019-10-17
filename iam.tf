resource "aws_iam_role" "ab_role" {
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.ab_role.name
}

resource "aws_iam_policy" "ab_tag_policy" {
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
  policy_arn = aws_iam_policy.ab_tag_policy.arn
  role       = aws_iam_role.ab_role.name
}

