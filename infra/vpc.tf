module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.9.0"

    name = local.name

    azs =[
        "${local.region}-a",
        "${local.region}-b",
        "${local.region}-c"
        ]

}