output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "vm_scale_set_id" {
  value = azurerm_linux_virtual_machine_scale_set.app.id
}
