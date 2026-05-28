locals {
  name_prefix = "${var.project_name}-${var.environment}"
  full_domain = "${var.sub_domain}.${var.base_domain}"
  region      = var.region

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  # Fetch the first 3 AZs from the current region
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnet_cidrs = {
    "${local.azs[0]}" = "10.0.1.0/24"
    "${local.azs[1]}" = "10.0.2.0/24"
    "${local.azs[2]}" = "10.0.3.0/24"
  }

  public_subnet_cidrs = {
    "${local.azs[0]}" = "10.0.4.0/24"
    "${local.azs[1]}" = "10.0.5.0/24"
    "${local.azs[2]}" = "10.0.6.0/24"
  }
}

  