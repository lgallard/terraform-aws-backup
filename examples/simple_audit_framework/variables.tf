variable "audit_config" {
  description = "Configuration for AWS Backup Audit Framework"
  type = object({
    framework = object({
      name        = string
      description = string
    })
    controls = object({
      retention_period = number
      resource_type    = string
    })
  })
  default = {
    framework = {
      name        = "simple-audit-framework"
      description = "Basic AWS Backup Audit Framework configuration"
    }
    controls = {
      retention_period = 30
      resource_type    = "EBS"
    }
  }
}
