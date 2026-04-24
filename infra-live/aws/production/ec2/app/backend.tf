terraform {
  backend "s3" {
    bucket         = "jb1-project-production-tf-state"
    key            = "production/ec2/app/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "jb1-project-production-tf-state-lock"
    encrypt        = true
  }
}
