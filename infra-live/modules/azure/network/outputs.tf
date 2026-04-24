output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "public_subnet_ids" {
  value = { for key, subnet in azurerm_subnet.public : key => subnet.id }
}

output "private_subnet_ids" {
  value = { for key, subnet in azurerm_subnet.private : key => subnet.id }
}

output "public_subnet_prefixes" {
  value = local.public_subnet_prefixes
}
