resource "aws_s3_bucket" "main" {
  count  = length(var.environment)
  bucket = "${var.bucket_name}-${var.environment[0]}"

  tags = {
    Name        = "${var.bucket_name}-${var.environment[0]}"
    Environment = var.environment[0]
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main" {
  count  = length(var.environment)
  bucket = aws_s3_bucket.main[count.index].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = length(var.environment)
  bucket = aws_s3_bucket.main[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "main" {
  count  = length(var.environment)
  bucket = aws_s3_bucket.main[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}