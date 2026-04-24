data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "jb1-project-development-tf-state"
    key    = "development/vpc/terraform.tfstate"
    region = var.eks.aws_region
  }
}
