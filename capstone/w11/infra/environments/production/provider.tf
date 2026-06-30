terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket               = "tfstate-capstone-cdo-03"
    key                  = "infra/environments/production/terraform.tfstate"
    region               = "ap-southeast-1"
    use_lockfile         = true
    encrypt              = true
    use_configurable_mfa = false
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.tags["Environment"]
      Owner       = var.tags["Owner"]
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}
