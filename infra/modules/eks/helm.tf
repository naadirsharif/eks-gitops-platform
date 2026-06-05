# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version = "4.11.0"
  
  create_namespace = true
  namespace        = "ingress-nginx"

  values = [file("${path.root}/../k8s/addons/nginx-ingress/values.yaml")]

  depends_on = [aws_eks_node_group.node_groups]
}