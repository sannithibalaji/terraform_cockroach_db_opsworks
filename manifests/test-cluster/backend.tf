terraform {
  required_version = "= 0.13.5"
  backend "s3" {
    bucket = "balajitest123"
    key    = "test/cockroach.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}