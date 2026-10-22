# Distribution CloudFront du site statique, HTTPS forcé

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.project}-oac"
  description                       = "Acces securise de CloudFront au bucket S3 prive"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# En-têtes de sécurité gérés par AWS : HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy
data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "MediTrack Online - diffusion du site statique"
  price_class         = "PriceClass_100" # Europe et Amérique du Nord

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-meditrack-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "s3-meditrack-site"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Certificat par défaut de CloudFront (domaine *.cloudfront.net)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  tags = { Name = "${var.project}-cloudfront" }
}
