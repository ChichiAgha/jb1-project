module "vpc" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/vpc?ref=develop"

  vpc = var.vpc
}
