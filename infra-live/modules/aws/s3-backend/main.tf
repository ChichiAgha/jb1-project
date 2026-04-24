terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.main, aws.backup]
    }
  }
}

resource "aws_s3_bucket" "state" {
  provider = aws.main
  bucket   = var.s3_backend.bucket_name

  tags = var.s3_backend.tags
}

resource "aws_s3_bucket_versioning" "state" {
  provider = aws.main
  bucket   = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  provider = aws.main
  bucket   = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  provider = aws.main
  bucket   = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "backup" {
  provider = aws.backup
  bucket   = var.s3_backend.bucket_name_backup

  tags = var.s3_backend.tags
}

resource "aws_s3_bucket_versioning" "backup" {
  provider = aws.backup
  bucket   = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  provider = aws.backup
  bucket   = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  provider = aws.backup
  bucket   = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  provider     = aws.main
  name         = var.s3_backend.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.s3_backend.tags
}
