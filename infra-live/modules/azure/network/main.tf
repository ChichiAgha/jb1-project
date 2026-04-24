resource "azurerm_virtual_network" "this" {
  name                = "${var.network.name_prefix}-vnet"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = var.network.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "public" {
  for_each = var.network.public_subnets

  name                 = "${var.network.name_prefix}-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_subnet" "private" {
  for_each = var.network.private_subnets

  name                 = "${var.network.name_prefix}-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_public_ip" "nat" {
  name                = "${var.network.name_prefix}-nat-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "${var.network.name_prefix}-nat"
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each = {
    for key in var.network.nat_gateway_subnet_keys : key => key
  }

  subnet_id      = azurerm_subnet.private[each.key].id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

locals {
  public_subnet_prefixes = flatten([for subnet in values(var.network.public_subnets) : subnet.address_prefixes])
}
