terraform {
  backend "s3" {
    bucket = "acme-terraform-state"
    key    = "acme-app/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.76.0"
    }
  }
}

provider "aws" {
  region = var.region
}
