variable "ecr" {
  description = "Sandbox ECR configuration object."
  type = object({
    aws_region           = string
    repository_names     = list(string)
    force_delete         = optional(bool, false)
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push         = optional(bool, true)
    encryption_type      = optional(string, "AES256")
    kms_key_arn          = optional(string, null)
    lifecycle_policy = optional(object({
      enabled              = optional(bool, false)
      max_image_count      = optional(number, 30)
      expire_untagged_days = optional(number, 14)
    }), {})
    name_prefix = string
    tags        = optional(map(string), {})
  })
}
