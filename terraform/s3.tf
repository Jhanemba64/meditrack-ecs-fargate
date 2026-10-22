# Bucket S3 privé du site statique, lu uniquement par CloudFront via OAC

data "aws_caller_identity" "current" {}

# L'ID du compte rend le nom du bucket unique
resource "aws_s3_bucket" "site" {
  bucket = "${var.project}-site-${data.aws_caller_identity.current.account_id}"
  tags   = { Name = "${var.project}-site" }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Anciennes versions des fichiers supprimées après 30 jours
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    id     = "expiration-anciennes-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.site]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  mime_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".json" = "application/json"
    ".txt"  = "text/plain"
  }
}

# Envoi des fichiers de ../site avec le bon Content-Type
resource "aws_s3_object" "site_files" {
  for_each = fileset("${path.module}/../site", "**")

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${path.module}/../site/${each.value}"
  etag         = filemd5("${path.module}/../site/${each.value}")
  content_type = try(local.mime_types[regex("\\.[^.]+$", each.value)], "application/octet-stream")
}

# Lecture autorisée uniquement pour la distribution CloudFront du projet
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AutoriseCloudFrontUniquement"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })
}
