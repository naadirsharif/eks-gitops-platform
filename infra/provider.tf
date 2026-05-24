terraform {
  backend "s3" {
    bucket = "eks-tfstate-lab-bucket"
    key    = "eks-gitops-platform"
    region = "eu-central-1"
    encrypt = true
    use_lockfile = true
  }

  required_version = ">=1.10"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 4.0"
    }
    helm = {
        source = "hashicorp/helm"
        version = ">= 2.6"
    }
  }
 } 

provider "aws" {
    region = "eu-central-1"
}

