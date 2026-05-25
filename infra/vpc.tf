resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr_block
  enable_dns_hostnames = true 

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


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = merge(local.tags, { Name = "${local.name_prefix}-private-rt" })
}


resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}