resource "aws_eks_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"


  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  role_arn = aws_iam_role.cluster.arn
  version  = "1.35"

  vpc_config {
    subnet_ids = var.private_subnet_ids

    public_access_cidrs    = ["0.0.0.0/0"]
    endpoint_public_access = true
  }
  # Encrypt Kubernetes secrets 
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

# Key Management Service
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption"
  deletion_window_in_days = 7

  tags = merge(var.tags, { Name = "${var.name_prefix}-eks-kms" })
}

# EKS Node Group
resource "aws_eks_node_group" "node_groups" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = ["t3a.large", "t3.large"]

  disk_size = "50"

  scaling_config {
    desired_size = var.node_desired_size # current number of nodes
    max_size     = var.node_max_size     # maximum nodes when scaling up
    min_size     = var.node_min_size     # minimum nodes always running
  }

  update_config {
    max_unavailable = 1
  }

   lifecycle {
    replace_triggered_by = [aws_eks_cluster.cluster.id]
  }


  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}