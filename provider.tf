terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket = "nico-s3-example-bucket-123456"
    key    = "envs/prod/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
