terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # backend "s3" {
  #     bucket       = var.s3_bucket_config.bucket
  #     key          = "terraform/terraform.tfstate"
  #     region       = "var.region
  #     use_lockfile = true
  # }
}

provider "aws" {
  region = var.region
}