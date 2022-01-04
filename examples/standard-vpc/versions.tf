terraform {
required_version = ">= 1.1.2"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.70.0"
    }
  }
  backend "s3" {
    bucket = "logicloud-test-tfm-backend"
    key    = "test-project1/terraform.tfstate"
    region = "us-east-1"
  }
}