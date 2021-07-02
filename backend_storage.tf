terraform {
  backend "s3" {
    bucket = "gerryhzgtest2021-terraform-state"
    key    = "state/myproject"
    region = "us-east-1"
  }
}
