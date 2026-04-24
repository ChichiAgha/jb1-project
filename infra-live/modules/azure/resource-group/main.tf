resource "azurerm_resource_group" "this" {
  count    = var.resource_group.create ? 1 : 0
  name     = coalesce(var.resource_group.name, "${var.resource_group.name_prefix}-rg")
  location = var.resource_group.location
  tags     = merge(var.tags, var.resource_group.tags)
}

data "azurerm_resource_group" "existing" {
  count = var.resource_group.create ? 0 : 1
  name  = var.resource_group.name
}

locals {
  resource_group_name     = var.resource_group.create ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_location = var.resource_group.create ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
}
