data "aws_iam_policy_document" "s3_policy_data" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.awswarriors.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["${aws_cloudfront_distribution.my_distribution.arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.awswarriors.id
  policy = data.aws_iam_policy_document.s3_policy_data.json
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "cloudfront OAC"
  description                       = "description of OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  // origin is where CloudFront gets its content from.
  origin {
    
    domain_name = "${aws_s3_bucket.awswarriors.bucket_regional_domain_name}"
    origin_id   = "my-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }
  
  enabled             = true
  default_root_object = "index.html"


  // All values are defaults from the AWS console.
  default_cache_behavior {
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id       = "my-s3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  

  // Here we're ensuring we can hit this distribution using www.runatlantis.io
  // rather than the domain name CloudFront gives us.
  aliases = ["${var.root_domain_name}"]

  price_class = "PriceClass_100"


  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
   
   viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:704964795421:certificate/57237ae3-b9c5-48d1-9be1-41f35cd3aa10"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }
}

