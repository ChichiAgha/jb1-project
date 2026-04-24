output "bucket_name" {
  value = module.s3_backend.bucket_name
}

output "dynamodb_table_name" {
  value = module.s3_backend.dynamodb_table_name
}

output "backend_config" {
  value = module.s3_backend.backend_config
}
