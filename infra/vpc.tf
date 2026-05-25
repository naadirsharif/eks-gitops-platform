resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = merge(local.tags, { Name = "${local.name_prefix}-vpc" })
}


resource "aws_subnet" "private_subnets" {
  for_each = local.private_subnet_cidrs

  vpc_id     = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block = each.value

  tags = merge(local.tags, { Name = "${local.name_prefix}-private-${each.key}" })
}

resource "aws_subnet" "public_subnets" {
  for_each = local.public_subnet_cidrs

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(local.tags, { Name = "${local.name_prefix}-public-${each.key}" })
}