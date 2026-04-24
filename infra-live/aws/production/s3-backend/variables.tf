variable "s3_backend" {
  description = "Production S3 backend configuration object."
  type = object({
    aws_region_main         = string
    aws_region_backup       = string
    bucket_name             = string
    force_destroy           = optional(bool, false)
    enable_versioning       = optional(bool, true)
    enable_replication      = optional(bool, true)
    dynamodb_read_capacity  = optional(number, 20)
    dynamodb_write_capacity = optional(number, 20)
    name_prefix             = string
    tags                    = optional(map(string), {})
  })
}
