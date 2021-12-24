terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.70.0"
    }
  }
  backend "s3" {
    bucket = "tpulliam-terraform-files"
    key    = "project1/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  # Configuration options
  region = var.region
}


variable "region" {
  type = string
  description = "region where the VPC should be deployed"
  default = "us-east-1"
}