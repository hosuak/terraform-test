terraform {
  required_providers {    # 필요한 제공자(provider) 지정
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "remote" {
    organization = "project_suah"  # 테라폼 클라우드 조직명
    workspaces {
      name = "terraform-test"  # 사용할 워크스페이스명
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}


