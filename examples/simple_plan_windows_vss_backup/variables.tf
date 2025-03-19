variable "env" {
  description = "Environment configuration map. Used to define environment-specific parameters like tags, resource names, and other settings"
  type        = map(any)
  default = {
    Environment = "prod"
    Owner       = "devops"
    Terraform   = true
  }
}
