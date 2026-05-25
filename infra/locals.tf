locals {
  name_prefix   = "nashar-eks-gitops"
  domain = "eks.nashar.dev"
  region = "eu-central-1" # Frankfurt region


  tags = {
    Environment = "lab"
    Project     = "eks-gitops-platform"
    Owner       = "Naadir"
    ManagedBy   = "terraform"
  }
}