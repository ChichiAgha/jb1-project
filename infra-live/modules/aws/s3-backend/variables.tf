variable "s3_backend" {
  description = "S3 backend infrastructure configuration object."
  type = object({
    aws_region_main     = string
    aws_region_backup   = string
    bucket_name         = string
    bucket_name_backup  = string
    dynamodb_table_name = string
    tags                = optional(map(string), {})
  })
}
