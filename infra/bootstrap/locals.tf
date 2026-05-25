locals {
  name_prefix = "nashar-eks-gitops"
  region = "eu-central-1" 

  tags = {
    Environment = "lab"
    Project     = "eks-gitops-platform"
    Owner       = "Naadir"
  }
}