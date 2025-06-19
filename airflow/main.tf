provider "aws" {
  region = "us-east-1"
  profile = "default"
}

resource "aws_s3_bucket" "news" {
  bucket = "news-store-bucket"

  tags = {
    Name = "news-store-bucket"
  }
}
