# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.0"

  create_namespace = true
  namespace        = "ingress-nginx"

  values = [file("${path.root}/../k8s/addons/nginx-ingress/values.yaml")]

  depends_on = [aws_eks_node_group.node_groups]
}

# Cert-Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.0"

  create_namespace = true
  namespace        = "cert-manager"

   values = [
    file("${path.root}/../k8s/addons/cert-manager/values.yaml"),
    <<-EOT
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "${aws_iam_role.cert_manager.arn}"
    EOT
  ]

  depends_on = [aws_eks_node_group.node_groups]
}

# External-DNS
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.21.1"

  create_namespace = true
  namespace        = "external-dns"

   values = [
    file("${path.root}/../k8s/addons/external-dns/values.yaml"),
    <<-EOT
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: "${aws_iam_role.external_dns.arn}"
    EOT
  ]

  depends_on = [aws_eks_node_group.node_groups]
}