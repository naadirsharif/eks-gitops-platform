module "vpc" {
  source               = "./modules/vpc"
  region               = var.region
  name_prefix          = local.name_prefix
  tags                 = local.tags
  vpc_cidr_block       = var.vpc_cidr_block
  private_subnet_cidrs = local.private_subnet_cidrs
  public_subnet_cidrs  = local.public_subnet_cidrs
}

module "eks" {
  source               = "./modules/eks"
  region               = var.region
  name_prefix          = local.name_prefix
  tags                 = local.tags
  zone_id              = var.zone_id
  vpc_cidr_block       = var.vpc_cidr_block
}