locals {
  region = "us-east-1"
}

provider "aws" {
  # Configuration options
  region = local.region
}