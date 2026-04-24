terraform {
  backend "s3" {
    bucket         = "jb1-project-sandbox-tf-state"
    key            = "sandbox/ec2/app/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "jb1-project-sandbox-tf-state-lock"
    encrypt        = true
  }
}
