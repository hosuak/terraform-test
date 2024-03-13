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
  profile = "admin"
}

# Create a VPC
resource "aws_vpc" "web-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create instance
resource "aws_instance" "web-ec2" {
  ami = "ami-0382ac14e5f06eb95"
  instance_type = "t2.micro"

  tags = {
    Name = "web-ec2"
  }
}