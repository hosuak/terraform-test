terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
  profile = var.profile_name
}

# Create a VPC
resource "aws_vpc" "web-vpc" {
  cidr_block = "10.0.0.0/16"
}