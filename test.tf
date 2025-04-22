provider "aws" {
  region  = "us-east-1" # adapte à ta région
  profile = "default"   # adapte à ton profil AWS
}

resource "aws_s3_bucket" "example" {
  bucket = "nico-s3-example-bucket-123456" # doit être globalement unique

  tags = {
    Name        = "Example S3 Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
