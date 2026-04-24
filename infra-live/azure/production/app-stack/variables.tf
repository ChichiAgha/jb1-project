variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
  sensitive   = true
}

variable "resource_group" {
  description = "Azure resource group configuration object."
  type = object({
    create      = optional(bool, true)
    name        = optional(string, null)
    location    = string
    name_prefix = string
    tags        = optional(map(string), {})
  })
}

variable "network" {
  description = "Azure virtual network and subnet configuration object."
  type = object({
    name_prefix   = string
    address_space = list(string)
    public_subnets = map(object({
      address_prefixes = list(string)
    }))
    private_subnets = map(object({
      address_prefixes = list(string)
    }))
    nat_gateway_subnet_keys = optional(list(string), [])
  })
}

variable "security" {
  description = "Azure network security configuration object."
  type = object({
    alb_ingress_cidrs = list(string)
    app_port          = optional(number, 80)
  })
}

variable "load_balancer" {
  description = "Azure Application Gateway configuration object."
  type = object({
    sku_name          = optional(string, "Standard_v2")
    sku_tier          = optional(string, "Standard_v2")
    capacity          = optional(number, 2)
    frontend_port     = optional(number, 80)
    backend_port      = optional(number, 80)
    health_check_path = optional(string, "/api/health")
  })
}

variable "compute" {
  description = "Azure VM Scale Set configuration object."
  type = object({
    vm_sku             = string
    instances          = number
    admin_username     = string
    ssh_public_key     = string
    dockerhub_username = string
    image_tag          = string
    zones              = optional(list(string), [])
    image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
    backend_env = object({
      app_env     = optional(string, "production")
      app_debug   = optional(string, "false")
      db_host     = string
      db_port     = string
      db_database = string
      db_username = string
      db_password = string
    })
  })
}

variable "tags" {
  description = "Common tags applied to all Azure resources."
  type        = map(string)
  default     = {}
}
