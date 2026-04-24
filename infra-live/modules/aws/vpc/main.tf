module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.17.0"

  name = "${var.vpc.name_prefix}-vpc"
  cidr = var.vpc.cidr_block

  azs             = var.vpc.availability_zones
  public_subnets  = var.vpc.public_subnets
  private_subnets = var.vpc.private_subnets

  enable_nat_gateway = var.vpc.enable_nat_gateway
  single_nat_gateway = var.vpc.single_nat_gateway

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = var.vpc.tags
}
