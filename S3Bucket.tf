resource "aws_s3_bucket" "bucket" {
  bucket = "awswarriorbucket"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  
}

resource "aws_s3_bucket_acl" "public_acls" {
    depends_on = [
      aws_s3_bucket_ownership_controls.bucket_ownership,
      aws_s3_bucket_public_access_block.public_access_block,
    ]
  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

locals {
  content_types = {
    ".html" : "text/html",
    ".css" : "text/css",
    ".js" : "text/javascript",
    ".mp4" : "video/mp4",
    ".png" : "image/png"
  }
}

resource "aws_s3_object" "file" {
  for_each     = fileset(path.module, "mys3app/**/*.{html,css,js,mp4,png}")
  bucket       = aws_s3_bucket.bucket.id
  key          = replace(each.value, "/^mys3app//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  etag         = filemd5(each.value)
}




resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "site" {
  depends_on = [
    aws_s3_bucket.bucket,
    aws_s3_bucket_public_access_block.public_access_block
  ]

  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
    ]
  })
}