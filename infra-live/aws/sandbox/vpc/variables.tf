variable "vpc" {
  description = "Sandbox VPC configuration object."
  type = object({
    aws_region           = string
    availability_zones   = list(string)
    cidr_block           = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    control_plane_names  = optional(list(string), [])
    enable_nat_gateway   = optional(bool, false)
    nat_gateway_count    = optional(number, 1)
    name_prefix          = string
    tags                 = optional(map(string), {})
  })
}
