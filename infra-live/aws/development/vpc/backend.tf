terraform {
  backend "s3" {
    bucket         = "jb1-project-development-tf-state"
    key            = "development/vpc/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "jb1-project-development-tf-state-lock"
    encrypt        = true
  }
}
