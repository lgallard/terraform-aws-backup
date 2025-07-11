provider "aws" {
  region = var.env["region"]
  # profile = var.env["profile"]  # Commented out for CI compatibility
}
