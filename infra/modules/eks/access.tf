resource "aws_eks_access_entry" "local_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::530193444530:user/Naadir-IAM-Admin"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "local_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = "arn:aws:iam::530193444530:user/Naadir-IAM-Admin"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}