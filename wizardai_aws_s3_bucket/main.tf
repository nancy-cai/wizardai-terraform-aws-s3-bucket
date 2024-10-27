# Create KMS key for server-side encryption
resource "aws_kms_key" "this" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.kms_policy.json

  # Prevent accidental deletion of the KMS key
  lifecycle {
    prevent_destroy = true
  }
}

# Create S3 bucket with enforced naming convention
resource "aws_s3_bucket" "this" {
  bucket = format("wizardai-%s-%s", var.bucket_name, var.environment)

  tags = {
    Name        = format("wizardai-%s-%s", var.bucket_name, var.environment)
    Environment = var.environment
  }
}

# Set private ACL for the main S3 bucket
resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

# Enforce ownership controls for the main bucket
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access to the main S3 bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Apply S3 bucket policy to enforce HTTPS-only access
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

# Enable server-side encryption with the KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
  }

  depends_on = [aws_kms_key.this]
}

# Enable versioning for the main S3 bucket (if specified)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Configure lifecycle rules for the main S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id      = rule.value["id"]
      status  = rule.value["status"]

      transition {
        days          = rule.value["transition_days"]
        storage_class = rule.value["storage_class"]
      }
    }
  }

  # Rule to expire noncurrent versions after specified days
  rule {
    id      = "expire-old-versions"
    status  = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}


# Create a separate logging bucket if logging is enabled
resource "aws_s3_bucket" "logs" {
  count  = var.logging_enabled ? 1 : 0
  bucket = "${var.bucket_name}-${var.environment}-logs"
}

# Enable logging for the main S3 bucket to the logging bucket
resource "aws_s3_bucket_logging" "this" {
  count         = var.logging_enabled ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "log/"
}

# Set ownership controls for the logging bucket
resource "aws_s3_bucket_ownership_controls" "logs" {
  count = var.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set ACL to allow log delivery to the logging bucket
resource "aws_s3_bucket_acl" "logs" {
  count  = var.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# Block all public access to the logging bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
