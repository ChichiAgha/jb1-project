module "s3_backend" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/s3-backend?ref=develop"

  providers = {
    aws.main   = aws.main
    aws.backup = aws.backup
  }

  s3_backend = var.s3_backend
}
