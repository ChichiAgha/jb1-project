variable "vpc" {
  description = "VPC configuration object."
  type = object({
    aws_region         = string
    availability_zones = list(string)
    cidr_block         = string
    public_subnets     = list(string)
    private_subnets    = list(string)
    enable_nat_gateway = optional(bool, true)
    single_nat_gateway = optional(bool, true)
    name_prefix        = string
    tags               = optional(map(string), {})
  })
}
