resource "aws_s3_bucket" "tf_state" {
  bucket           = "${local.name_prefix}-tfstate-bucket"
  bucket_namespace = "global"

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}