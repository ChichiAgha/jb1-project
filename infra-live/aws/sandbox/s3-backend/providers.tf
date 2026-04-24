terraform {
  required_version = ">= 1.10.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "main"
  region = var.s3_backend.aws_region_main
}

provider "aws" {
  alias  = "backup"
  region = var.s3_backend.aws_region_backup
}
