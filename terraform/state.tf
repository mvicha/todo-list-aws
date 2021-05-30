terraform {
  backend "s3" {
    bucket  = "mvicha-terraform-state"
    key     = "newjenkins.state"
    region  = "us-east-1"
  }
}

