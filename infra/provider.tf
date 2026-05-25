terraform {

  required_version = ">=1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

