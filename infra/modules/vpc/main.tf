# VPC with DNS hostnames enabled for EKS node registration
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

# Private subnets for EKS worker nodes 
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnet_cidrs

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = merge(var.tags, {
    Name                              = "${var.name_prefix}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Public subnets for load balancer
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnet_cidrs

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.name_prefix}-public-${each.key}"
    "kubernetes.io/role/elb" = "1"
  })
}

# Internet gateway for outbound public internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# Elastic IP
resource "aws_eip" "ngw" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

# Regional NAT gateway so private subnets can reach the internet
resource "aws_nat_gateway" "ngw" {
  allocation_id     = aws_eip.ngw.id
  subnet_id         = values(aws_subnet.public_subnets)[0].id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "${var.name_prefix}-ngw" })
}

# Route table for public subnets: sends all traffic to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

# Route table for private subnets: sends all traffic through the NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-private-rt" })
}

# Route table associations
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}