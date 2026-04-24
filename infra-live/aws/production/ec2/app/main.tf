data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state.bucket
    key    = var.vpc_remote_state.key
    region = var.vpc_remote_state.region
  }
}

module "app" {
  source = "../../../../../modules/aws/alb-asg"

  network = {
    name_prefix        = var.app_stack.name_prefix
    vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
    public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnets
    private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  }

  security      = var.app_stack.security
  load_balancer = var.app_stack.load_balancer
  compute       = var.app_stack.compute
  tags          = var.app_stack.tags
}
