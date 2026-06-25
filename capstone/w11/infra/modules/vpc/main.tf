resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.project_name}-private-subnet-${each.key}"
  }
}

resource "aws_subnet" "database" {
  for_each          = var.database_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.project_name}-db-subnet-${each.key}"
  }
}

resource "aws_eip" "nat" {
  for_each = var.nat_gateways
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${each.key}"
  }
}

resource "aws_nat_gateway" "this" {
  for_each      = var.nat_gateways
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.public_subnet_key].id

  tags = {
    Name = "${var.project_name}-nat-gw-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.private_route_tables
  vpc_id   = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-private-rt-${each.key}"
  }
}

resource "aws_route" "private_nat" {
  for_each               = { for k, v in var.private_route_tables : k => v if v.nat_gateway_key != null && v.nat_gateway_key != "" }
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value.nat_gateway_key].id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value.route_table_key].id
}

resource "aws_route_table" "database" {
  for_each = var.database_route_tables
  vpc_id   = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-db-rt-${each.key}"
  }
}

resource "aws_route_table_association" "database" {
  for_each       = var.database_subnets
  subnet_id      = aws_subnet.database[each.key].id
  route_table_id = aws_route_table.database[each.value.route_table_key].id
}
