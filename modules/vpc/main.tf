resource "aws_vpc" "this" {
  cidr_block = var.cidr
  instance_tenancy = "default"

  // If both attributes are enabled, an instance launched into the 
  // VPC receives a public DNS hostname if it is assigned a 
  // public IPv4 address or an Elastic IP address at creation.
  enable_dns_support = true
  enable_dns_hostnames = false

  tags = merge(
    {
      Name = var.name,
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"

  tags = merge(
    {
      Name = "${var.name}-s3-endpoint"
    },
    var.tags,
  )
}


// Internet Gateway is required to allow internet traffic to your vpc
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-igw"
    },
    var.tags,
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = element(var.public_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = "${var.name}-public"
    },
    var.tags,
  )
}

resource "aws_subnet" "private" {
  count = length(var.public_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = element(var.private_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = "${var.name}-private"
    },
    var.tags,
  )
}

resource "aws_subnet" "intra" {
  count = length(var.intra_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = element(var.intra_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge(
    {
      Name = "${var.name}-intra"
    },
    var.tags,
  )
}

resource "aws_nat_gateway" "this" {
  // One nat gateway per Availability Zone
  count = length(var.azs)

  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.nat.*.id, count.index)

  tags = merge(
    {
      Name = "${var.name}-nat"
    },
      var.tags,
  )
}


resource "aws_eip" "nat" {
  count = length(var.azs)

  vpc      = true
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.this]

  tags = merge(
    {
      Name = "${var.name}-eip"
    },
      var.tags,
  )
}


resource "aws_route_table" "public" {
  count = length(var.public_subnets)

  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.name}-rt-public"
    },
      var.tags,
  )
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.this.*.id, count.index)
  }

  tags = merge(
    {
      Name = "${var.name}-rt-private"
    },
    var.tags,
  )
}

resource "aws_route_table_association" "public_assoc" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

resource "aws_route_table_association" "private_assoc" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}


