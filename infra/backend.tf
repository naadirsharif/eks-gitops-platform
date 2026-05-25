terraform {
    backend "s3" {
        bucket       = "${local.name_prefix}-tfstate-bucket"
        key          = "eks-gitops-platform"
        region       = "eu-central-1"
        encrypt      = true
        use_lockfile = true
    }
}