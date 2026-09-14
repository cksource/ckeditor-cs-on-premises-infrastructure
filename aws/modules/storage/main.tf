terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# S3 bucket names are globally unique, so the configured prefix gets a random
# suffix rather than colliding with every other deployment of this example.
resource "random_string" "id" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "storage" {
  bucket = "${var.bucket_prefix}-${random_string.id.result}"

  tags = {
    Name = var.name
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket                  = aws_s3_bucket.storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
