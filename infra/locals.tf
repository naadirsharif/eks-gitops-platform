locals {
  name   = "eks-lab"
  domain = "lab.nashar.dev"
  region = "eu-central-1" # Frankfurt region


  tags = {
    Environment = "sandbox"
    Project     = "eks-gitops-platform"
    Owner       = "Naadir"
  }
}