# --- VPC ---
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr 
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.environment}-vpc"
  }
}

# --- SUBNETS ---
resource "aws_subnet" "subnet_public" {
  # On boucle sur la liste d'objets. 
  # 'index' est la position (0, 1...) et 'subnet' est l'objet {cidr_block = "...", az = "..."}
  for_each = {
    for index, subnet in var.public_subnets_cidr : subnet.cidr_block => subnet
  }

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-subnet-public-${each.value.az}"
  }
}

resource "aws_subnet" "subnet_private" {
  # Même logique pour le privé
  for_each = {
    for index, subnet in var.private_subnets_cidr : subnet.cidr_block => subnet
  }
  
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "${var.environment}-subnet-private-${each.value.az}"
  }
}

# --- GATEWAY ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
  
  tags = {
    Name = "${var.environment}-igw"
  }
}

# --- ROUTE TABLES ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# --- ROUTE TABLE ASSOCIATIONS ---
resource "aws_route_table_association" "public_rt_assoc" {
  for_each       = aws_subnet.subnet_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  for_each       = aws_subnet.subnet_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}