terraform {
    required_version = "~> 1.7"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }

    # backend "s3" {
    #     bucket       = "mybucket"
    #     key          = "path/to/my/key"
    #     region       = "us-east-1"
    #     use_lockfile = true
    # }
}

provider "aws" {
    region = "us-east-1"
}