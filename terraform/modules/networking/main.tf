resource "aws_vpc" "main" {
  count             = length(var.vpc_cidr_blocks)
  cidr_block        = var.vpc_cidr_blocks[count.index]  
  tags = {
    Name        = "${var.environment[count.index]}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones[count.index]) * 1  
  vpc_id            = aws_vpc.main[count.index].id
  cidr_block        = var.subnet_cidrs[count.index][count.index % length(var.subnet_cidrs[count.index])].public_cidr
  availability_zone = var.availability_zones[count.index][count.index % length(var.availability_zones[count.index])]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment[count.index]}-public-subnet-${count.index + 1}"
    Type        = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones[count.index]) * 1  # One private subnet per AZ
  vpc_id            = aws_vpc.main[count.index].id
  cidr_block        = var.subnet_cidrs[count.index][count.index % length(var.subnet_cidrs[count.index])].private_cidr
  availability_zone = var.availability_zones[count.index][count.index % length(var.availability_zones[count.index])]

  tags = {
    Name        = "${var.environment[count.index]}-private-subnet-${count.index + 1}"
    Type        = "Private"
  }
}

resource "aws_subnet" "db" {
  count             = length(var.availability_zones[count.index]) * 1  # One database subnet per AZ
  vpc_id            = aws_vpc.main[count.index].id
  cidr_block        = var.subnet_cidrs[count.index][count.index % length(var.subnet_cidrs[count.index])].db_cidr
  availability_zone = var.availability_zones[count.index][count.index % length(var.availability_zones[count.index])]

  tags = {
    Name        = "${var.environment[count.index]}-db-subnet-${count.index + 1}"
    Type        = "Database"
  }
}

resource "aws_nat_gateway" "gw" {
  count             = length(var.availability_zones[count.index])  # One NAT Gateway per AZ
  allocation_id     = aws_eip.nat[count.index].id
  subnet_id         = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.environment[count.index]}-nat-gateway"
  }
}

resource "aws_eip" "nat" {
  count = length(var.availability_zones[count.index])  # One Elastic IP per NAT Gateway
  vpc = true 
}


# Public Route Tables (One per VPC)
resource "aws_route_table" "public" {
  count  = length(var.vpc_cidr_blocks)  # Creates 3 route tables (dev, staging, prod)
  vpc_id = aws_vpc.main[count.index].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "${var.environment[count.index]}-public-route-table"
  }
}

# Private Route Tables (One per VPC)
resource "aws_route_table" "private" {
  count  = length(var.vpc_cidr_blocks)  # Creates 3 route tables (dev, staging, prod)
  vpc_id = aws_vpc.main[count.index].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[count.index].id  # References the NAT Gateway in the VPC
  }

  tags = {
    Name = "${var.environment[count.index]}-private-route-table"
  }
}


# Public Subnet Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones[count.index])
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Private Subnet Route Table Associations
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones[count.index])
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database Subnet Route Table Associations
resource "aws_route_table_association" "database" {
  count          = length(var.availability_zones[count.index])
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private[count.index].id  # DB subnets use private route table
}