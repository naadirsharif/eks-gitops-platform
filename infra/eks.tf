module "eks" {
    source = "terraform-aws-modules/eks/aws"
    
    cluster_name = local.name 
    cluster_version = "1.23"
}