terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "xbrain-080-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "xbrain-080-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.tags.Environment
      Project     = var.tags.Project
      Owner       = var.tags.Owner
      ManagedBy   = "Terraform"
    }
  }
}
