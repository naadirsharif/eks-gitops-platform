region         = "eu-central-1"
vpc_cidr_block = "10.0.0.0/16"

project_name = "eks-gitops-platform"
owner        = "Naadir"
environment  = "lab"

base_domain = "lab.nashar.dev"
sub_domain  = "eks"
zone_id     = "Z00208033796D8OPHFLPL"

node_desired_size = 3
node_max_size     = 3
node_min_size     = 1
