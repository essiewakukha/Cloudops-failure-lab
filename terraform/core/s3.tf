data "aws_caller_identity" "current" {}

# Target of the Terraform-rename scenario (13).
resource "aws_s3_bucket" "data" {
  bucket        = "${var.name}-${data.aws_caller_identity.current.account_id}-${var.region}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}