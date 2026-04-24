output "resource_group_name" {
  description = "Azure resource group name."
  value       = module.resource_group.resource_group_name
}

output "virtual_network_id" {
  description = "Azure virtual network ID."
  value       = module.network.virtual_network_id
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Azure Application Gateway."
  value       = module.app.application_gateway_public_ip
}

output "vm_scale_set_id" {
  description = "Azure Linux VM Scale Set ID."
  value       = module.app.vm_scale_set_id
}
