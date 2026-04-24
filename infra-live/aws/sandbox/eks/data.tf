data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "jb1-project-sandbox-tf-state"
    key    = "sandbox/vpc/terraform.tfstate"
    region = var.eks.aws_region
  }
}
