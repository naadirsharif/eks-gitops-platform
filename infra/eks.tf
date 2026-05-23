module "eks" {
    source = "terraform-aws-modules/eks/aws"
    
    cluster_name = local.name 
    cluster_version = "1.28"

    cluster_endpoint_public_access = true
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] 

    enable_irsa = true 

    vpc_id = module.vpc.id
    subnet_ids = module.vpc.private_subnets 
    control_plane_subnet_ids = module.vpc.public_subnets

}