locals {
  public_subnet_keys  = sort(keys(var.public_subnet_ids))
  private_subnet_keys = sort(keys(var.private_subnet_ids))
  public_subnet_key   = local.public_subnet_keys[0]
  private_subnet_key  = local.private_subnet_keys[0]

  custom_data = base64encode(templatefile("${path.module}/templates/cloud_init.tftpl", {
    dockerhub_username = var.compute.dockerhub_username
    image_tag          = var.compute.image_tag
    app_port           = var.security.app_port
    app_env            = var.compute.backend_env.app_env
    app_debug          = var.compute.backend_env.app_debug
    db_host            = var.compute.backend_env.db_host
    db_port            = var.compute.backend_env.db_port
    db_database        = var.compute.backend_env.db_database
    db_username        = var.compute.backend_env.db_username
    db_password        = var.compute.backend_env.db_password
  }))
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.name_prefix}-public-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.name_prefix}-private-nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "public_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.load_balancer.frontend_port)
  source_address_prefixes     = var.security.alb_ingress_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_gateway_manager" {
  name                        = "allow-gateway-manager"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "private_app" {
  name                        = "allow-app-from-appgw-subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.security.app_port)
  source_address_prefixes     = var.public_subnet_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.private.name
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each = var.public_subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each = var.private_subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.name_prefix}-appgw-pip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "this" {
  name                = "${var.name_prefix}-appgw"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name     = var.load_balancer.sku_name
    tier     = var.load_balancer.sku_tier
    capacity = var.load_balancer.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.public_subnet_ids[local.public_subnet_key]
  }

  frontend_port {
    name = "frontend-port"
    port = var.load_balancer.frontend_port
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "app-backend-pool"
  }

  backend_http_settings {
    name                  = "app-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = var.load_balancer.health_check_path
    port                  = var.load_balancer.backend_port
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "app-health-probe"
  }

  probe {
    name                                      = "app-health-probe"
    protocol                                  = "Http"
    path                                      = var.load_balancer.health_check_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "app-backend-pool"
    backend_http_settings_name = "app-http-settings"
    priority                   = 100
  }
}

locals {
  appgw_backend_pool_id = tolist(azurerm_application_gateway.this.backend_address_pool)[0].id
}

resource "azurerm_linux_virtual_machine_scale_set" "app" {
  name                            = "${var.name_prefix}-vmss"
  computer_name_prefix            = "${var.name_prefix}vm"
  location                        = var.resource_group_location
  resource_group_name             = var.resource_group_name
  sku                             = var.compute.vm_sku
  instances                       = var.compute.instances
  admin_username                  = var.compute.admin_username
  custom_data                     = local.custom_data
  tags                            = var.tags
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.compute.admin_username
    public_key = var.compute.ssh_public_key
  }

  source_image_reference {
    publisher = var.compute.image_reference.publisher
    offer     = var.compute.image_reference.offer
    sku       = var.compute.image_reference.sku
    version   = var.compute.image_reference.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  zone_balance = length(var.compute.zones) > 0 ? true : null
  zones        = length(var.compute.zones) > 0 ? var.compute.zones : null

  network_interface {
    name    = "app-nic"
    primary = true

    ip_configuration {
      name      = "app-ip-config"
      primary   = true
      subnet_id = var.private_subnet_ids[local.private_subnet_key]
      application_gateway_backend_address_pool_ids = [
        local.appgw_backend_pool_id
      ]
    }
  }
}
