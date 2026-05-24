terraform {
  backend "s3" {
    bucket = "eks-tfstate-lab-bucket"
    key    = "eks-gitops-platform"
    region = "eu-central-1"
    encrypt = true
  }

  required_version = ">=1.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 4.0"
    }
  }
}
