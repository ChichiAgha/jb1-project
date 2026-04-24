variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
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

variable "tags" {
  type    = map(string)
  default = {}
}
