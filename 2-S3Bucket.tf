resource "aws_s3_bucket" "awswarriors" {
  bucket = "awswarriors"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.awswarriors.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  
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
  for_each     = fileset(path.module, "mys3app/**/*.{html,css,js,mp4,png}") #mys3app is the folder that contains the objects to upload to bucket
  bucket       = aws_s3_bucket.awswarriors.id
  key          = replace(each.value, "/^mys3app//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  etag         = filemd5(each.value)
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.awswarriors.id
  index_document {
    suffix = "index.html"
  }
}

