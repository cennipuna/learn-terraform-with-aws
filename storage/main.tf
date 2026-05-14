terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ── EBS Volume for MySQL data ─────────────────────────────────────────────────
# This persists across environment up/down cycles.
# The EC2 DB server attaches this volume on boot and mounts it as /var/lib/mysql.
resource "aws_ebs_volume" "mysql_data" {
  availability_zone = "${var.aws_region}a"
  size              = var.volume_size_gb
  type              = "gp3"

  tags = {
    Name = "restaurant-mysql-data"
  }
}

# ── S3 Bucket for media uploads ───────────────────────────────────────────────
# Name is globally unique by embedding the AWS account ID.
# Persists across environment up/down cycles like the EBS volume.
resource "aws_s3_bucket" "media" {
  bucket = "restaurant-media-${data.aws_caller_identity.current.account_id}"

  tags = { Name = "restaurant-media" }
}

# Enable ACLs so Laravel can mark uploaded objects as public-read.
resource "aws_s3_bucket_ownership_controls" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket_ownership_controls.media]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}
