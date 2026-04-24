locals {
  common_tags = merge(var.tags, var.resource_group.tags, {
    Environment = "production"
    Stack       = "${var.resource_group.name_prefix}-app"
    ManagedBy   = "terraform"
  })
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  resource_group = var.resource_group
  tags           = local.common_tags
}

module "network" {
  source = "../../../modules/azure/network"

  resource_group_name     = module.resource_group.resource_group_name
  resource_group_location = module.resource_group.resource_group_location
  network                 = var.network
  tags                    = local.common_tags
}

module "app" {
  source = "../../../modules/azure/app-stack"

  resource_group_name     = module.resource_group.resource_group_name
  resource_group_location = module.resource_group.resource_group_location
  public_subnet_ids       = module.network.public_subnet_ids
  private_subnet_ids      = module.network.private_subnet_ids
  public_subnet_prefixes  = module.network.public_subnet_prefixes
  name_prefix             = var.resource_group.name_prefix
  security                = var.security
  load_balancer           = var.load_balancer
  compute                 = var.compute
  tags                    = local.common_tags
}
