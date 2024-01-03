resource "aws_backup_report_plan" "ab_report" {
  for_each = { for report in var.reports : report.name => report }

  name        = each.value.name
  description = each.value.description

  report_delivery_channel {
    formats        = each.value.formats
    s3_bucket_name = each.value.s3_bucket_name
    s3_key_prefix  = each.value.s3_key_prefix
  }

  report_setting {
    report_template      = each.value.report_template
    accounts             = each.value.accounts
    organization_units   = each.value.organization_units
    regions              = each.value.regions
    framework_arns       = each.value.framework_arns
    number_of_frameworks = length(each.value.framework_arns)
  }

  tags = var.tags
}
