resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block

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
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-public-${each.key}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.tags, { Name = "${local.name_prefix}-igw" })
}

resource "aws_nat_gateway" "ngw" {
  vpc_id = aws_vpc.vpc.id
  availability_mode = "regional"
  connectivity_type = "public"
  depends_on = [aws_internet_gateway.igw]

  tags = merge(local.tags, { Name = "${local.name_prefix}-ngw" })
}