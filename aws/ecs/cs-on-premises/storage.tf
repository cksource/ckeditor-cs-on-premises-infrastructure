resource "random_string" "id" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "storage" {
  bucket = "cs-on-premises-storage-${random_string.id.result}"

  tags = {
    Name = "CS On-Premises Storage"
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
