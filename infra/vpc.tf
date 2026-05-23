module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.9.0"

    name = local.name

    azs =[
        "${local.region}-a",
        "${local.region}-b",
        "${local.region}-c"
    ]

    private_subnets = [
        "10.0.1.0/24", 
        "10.0.2.0/24",
        "10.0.3.0/24"
    ]
}
