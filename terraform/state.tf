terraform {
  backend "s3" {
    bucket  = "mvicha-terraform-state"
    key     = "jenkins.state"
    region  = "us-east-1"
  }
}
