data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "jb1-project-production-tf-state"
    key    = "production/vpc/terraform.tfstate"
    region = var.eks.aws_region
  }
}
