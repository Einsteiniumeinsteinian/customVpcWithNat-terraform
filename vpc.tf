resource "aws_vpc" "sales_vpc" {
  cidr_block           = var.sales_vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name"        = "sale-vpc"
    "Environment" = var.environment
  }
}

# internet gateway
resource "aws_internet_gateway" "sales_igw" {
  vpc_id = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]

  tags = {
    "Name" = "sales_${var.environment}_igw"
  }
}

# nat gateway
/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.sales_igw]
}
/* NAT */

resource "aws_nat_gateway" "sales_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.sales_public_subnet.*.id, 0)
  depends_on = [aws_internet_gateway.sales_igw, aws_eip.nat_eip]
  tags = {
    Name = "sales NAT"
    Environment = "${var.environment}"
  }
}

# Private Subnet 
resource "aws_subnet" "sales_private_subnet" {
  vpc_id = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]
  count                   = length(var.sales_private_subnet)
  cidr_block              = element(var.sales_private_subnet, count.index)
  availability_zone       = element(var.sales_AZ, count.index)
  map_public_ip_on_launch = false

  tags = {
    "Name"        = "private_${var.environment}_${element(var.sales_AZ, count.index)}_subnet"
    "Environment" = var.environment
    "Number"      = count.index
  }
}

# public Subnet

resource "aws_subnet" "sales_public_subnet" {
  vpc_id = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]
  count                   = length(var.sales_public_subnet)
  cidr_block              = element(var.sales_public_subnet, count.index)
  availability_zone       = element(var.sales_AZ, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name"        = "public_${var.environment}_${element(var.sales_AZ, count.index)}_subnet"
    "Environment" = var.environment
    "count"       = count.index
  }
}

resource "aws_route_table" "public_sales_rtb" {
  vpc_id = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sales_igw.id
  }

  tags = {
    "Name" = "public_sales_${var.environment}_rtb"
  }
}
  

  resource "aws_route_table" "private_sales_rtb" {
  vpc_id = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sales_nat.id
  }

  tags = {
    "Name" = "private_sales_${var.environment}_rtb"
  }
}

# Public Route table association
resource "aws_route_table_association" "public_sales_rtba" {
  count = length(var.sales_public_subnet)
  depends_on = [
    aws_route_table.public_sales_rtb
  ]
  subnet_id      = element(aws_subnet.sales_public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_sales_rtb.id
}

# Private Route table association for nat gateway
resource "aws_route_table_association" "private_sales_rtba" {
  count = length(var.sales_private_subnet)
  depends_on = [
    aws_route_table.private_sales_rtb
  ]
  subnet_id      = element(aws_subnet.sales_private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private_sales_rtb.id
}

# Secuirty Group
locals {
  ports_in = [22, 443, 80]
  #   port_out = [0]
}

resource "aws_security_group" "sales_sg" {
  name        = "sales_sg"
  description = "Allow inbound traffic for sales vpc"
  vpc_id      = aws_vpc.sales_vpc.id
  depends_on = [
    aws_vpc.sales_vpc
  ]

  dynamic "ingress" {
    for_each = local.ports_in
    content {
      description = "allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["105.112.28.161/32"]
      self        = true
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = true
  }

  tags = {
    "Name" = "sales_sg"
  }
}

