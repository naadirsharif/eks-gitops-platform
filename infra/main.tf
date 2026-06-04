module "vpc" {
  source               = "./modules/vpc"
  name_prefix          = local.name_prefix
  tags                 = local.tags
  vpc_cidr_block       = var.vpc_cidr_block
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs
}