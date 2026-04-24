variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "public_subnet_ids" {
  type = map(string)
}

variable "private_subnet_ids" {
  type = map(string)
}

variable "public_subnet_prefixes" {
  type = list(string)
}

variable "name_prefix" {
  type = string
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
  type    = map(string)
  default = {}
}
