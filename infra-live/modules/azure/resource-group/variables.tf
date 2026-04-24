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

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
