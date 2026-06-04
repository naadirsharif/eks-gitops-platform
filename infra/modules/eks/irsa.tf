## OIDC Provider | allows AWS to trust tokens issued by this cluster

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]

  tags = merge(local.tags, { Name = "${local.name_prefix}-oidc" })
}


## Cert Manager IRSA
## Allows cert-manager to create DNS records in Route53 for SSL validation

resource "aws_iam_role" "cert_manager" {
  name = "${local.name_prefix}-cert-manager"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.cluster.url}:sub" = "system:serviceaccount:cert-manager:cert-manager"
        }
      }
    }]
  })

  tags = merge(local.tags, { Name = "${local.name_prefix}-cert-manager" })
}

## Route53 permissions for cert-manager pod
## source: https://cert-manager.io/docs/configuration/acme/dns01/route53/
resource "aws_iam_policy" "cert_manager" {
  name = "${local.name_prefix}-cert-manager-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${var.zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

## External DNS IRSA
## Automatically creates Route53 DNS records when app is deployed
resource "aws_iam_role" "external_dns" {
  name = "${local.name_prefix}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.cluster.arn
      }
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.cluster.url}:sub" = "system:serviceaccount:external-dns:external-dns"
        }
      }
    }]
  })

  tags = merge(local.tags, { Name = "${local.name_prefix}-external-dns" })
}

## Route53 permissions for external DNS pod
## source: https://repost.aws/knowledge-center/eks-set-up-externaldns
resource "aws_iam_policy" "external_dns" {
  name = "${local.name_prefix}-external-dns-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource" : [
          "arn:aws:route53:::hostedzone/${var.zone_id}"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}


## Community module setup (not used atm)

# module "cert_manager_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "6.6.0"

#   name                          = "cert-manager"
#   attach_cert_manager_policy    = true
#   cert_manager_hosted_zone_arns = ["arn:aws:route53:::/hostedzone/Z00208033796D8OPHFLPL"]

#   oidc_providers = {
#     eks = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["cert-manager:cert-manager"]
#     }
#   }

#   tags = local.tags
# }

# ## External DNS IRSA
# ## # -> Automatically creates Route53 DNS records when app is deployed

# module "external_dns_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "6.6.0"

#   name                          = "external-dns"
#   attach_external_dns_policy    = true
#   external_dns_hosted_zone_arns = ["arn:aws:route53:::/hostedzone/Z00208033796D8OPHFLPL"]

#   oidc_providers = {
#     eks = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["external-dns:external-dns"]
#     }
#   }

#   tags = local.tags
# }






 