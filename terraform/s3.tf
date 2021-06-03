resource "aws_s3_bucket" "s3_bucket_development" {
  bucket = "es-unir-development-s3-${random_integer.server.result}-artifacts"
  acl    = "private"

  tags = {
    Name        = "es-unir-development-s3-${random_integer.server.result}-artifacts"
    Country     = "es"
    Team        = "unir"
    Environment = "development"
  }

  depends_on = [random_integer.server]
}

resource "aws_s3_bucket" "s3_bucket_staging" {
  bucket = "es-unir-staging-s3-${random_integer.server.result}-artifacts"
  acl    = "private"

  tags = {
    Name        = "es-unir-staging-s3-${random_integer.server.result}-artifacts"
    Country     = "es"
    Team        = "unir"
    Environment = "staging"
  }

  depends_on = [random_integer.server]
}


resource "aws_s3_bucket" "s3_bucket_production" {
  bucket = "es-unir-production-s3-${random_integer.server.result}-artifacts"
  acl    = "private"

  tags = {
    Name        = "es-unir-production-s3-${random_integer.server.result}-artifacts"
    Country     = "es"
    Team        = "unir"
    Environment = "production"
  }

  depends_on = [random_integer.server]

}
