provider "aws" {
  region  = var.env["region"]
  profile = var.env["profile"]
}
