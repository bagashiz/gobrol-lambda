terraform {
  cloud {
    organization = "bagashiz"

    workspaces {
      name = "gobrol-lambda"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.2"
    }
  }

  required_version = "~> 1.5"
}

provider "aws" {
  region = var.region
}
