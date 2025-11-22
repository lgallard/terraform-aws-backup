# Region Settings Variables

variable "region" {
  description = "AWS region for region settings configuration"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "example"
    Purpose     = "RegionSettings"
  }
}
