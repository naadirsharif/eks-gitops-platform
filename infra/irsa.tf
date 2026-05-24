 # Cert manager IRSA (IAM roles for service accounts)

 module "cert_manager_irsa_role" {
    source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
    version = "6.6.0"
    
    name = "cert_manager"
    attach_cert_manager_policy = true 
    cert_manager_hosted_zone_arns = ["arn:aws:route53:::/hostedzone/Z00208033796D8OPHFLPL"]

    oidc_providers = {
        eks = {
            provider_arn = module.eks.oidc_provider_arn
            namespace_service_accounts = ["cert-manager:cert-manager"]
        }
    }
    tags = local.tags
 }
 