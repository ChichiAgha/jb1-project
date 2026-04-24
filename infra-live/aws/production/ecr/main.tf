module "ecr" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/ecr?ref=develop"

  ecr = var.ecr
}
