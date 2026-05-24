module "eks" {
    source = "terraform-aws-modules/eks/aws"
    
    name = local.name 
    kubernetes_version = "1.28"

    endpoint_public_access = true
    endpoint_public_access_cidrs = ["0.0.0.0/0"] 

    enable_irsa = true 

    vpc_id = module.vpc.id
    subnet_ids = module.vpc.private_subnets 
    control_plane_subnet_ids = module.vpc.public_subnets

    eks_managed_node_groups = {
        disk_size = 50
        instance_types = ["t3a.large", "t3.large"]
    }
    tags = local.tags
}