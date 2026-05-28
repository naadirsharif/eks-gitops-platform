terraform {
  backend "s3" {
    bucket       = "nashar-eks-gitops-tfstate-bucket"
    key          = "eks-gitops-platform"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}