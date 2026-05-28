resource "aws_eks_cluster" "cluster" {
  name = "${local.name_prefix}-cluster"


  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    vpc_id = aws_vpc.vpc.id
    subnet_ids = [ aws_subnet.private_subnets.id ]  # Subnets for workernodes 

    public_access_cidrs = "0.0.0.0/0"
    endpoint_public_access = true
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "cluster" {
  name = local.name_prefix
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}



# module "eks" {
#   source = "terraform-aws-modules/eks/aws"

#   name               = local.name_prefix
#   kubernetes_version = "1.28"

#   endpoint_public_access       = true
#   endpoint_public_access_cidrs = ["0.0.0.0/0"]

#   enable_irsa = true ## IAM roles for service accounts
#   ## Enables OIDC provider for pod-level AWS permissions

#   vpc_id                   = module.vpc.vpc_id
#   subnet_ids               = module.vpc.private_subnets
#   control_plane_subnet_ids = module.vpc.public_subnets

#   eks_managed_node_groups = {
#     default = {
#       disk_size      = 50
#       instance_types = ["t3a.large", "t3.large"]
#     }
#   }
#   tags = local.tags
# }