# Specify the Terraform provider
provider "aws" {
  region = "us-east-2"
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "assignment4-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  count                   = 1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.0.0.0/22", "10.0.4.0/22"], count.index)
  availability_zone       = element(["us-east-2a"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets2" {
  count                   = 1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.0.8.0/22", "10.0.12.0/22"], count.index)
  availability_zone       = element(["us-east-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "assignment4-igw"
  }
}


# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "assignment4-public-route-table"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = 1
  subnet_id      = aws_subnet.public_subnets[count.index].id
  subnet_id      = aws_subnet.public_subnets2[count.index].id
  route_table_id = aws_route_table.public.id
}


# Security Group for master
resource "aws_security_group" "master" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "master"
  }
}

# master Host
resource "aws_instance" "master" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.master.id]
  key_name      = "ohio2"

  tags = {
    Name = "master-host"
  }
}

# master2 Host
resource "aws_instance" "master2" {
  ami           = "ami-036841078a4b68e14"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets2[0].id
  vpc_security_group_ids = [aws_security_group.master.id]
  key_name      = "ohio2"

  tags = {
    Name = "master2-host"
  }
}

# VPC Peering
resource "aws_vpc_peering_connection" "vpc_peering" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = "vpc-048c60e69d4e85c1b" # Replace with your Default VPC ID

  tags = {
    Name = "assignment4-vpc-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "vpc_peering_accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true

  tags = {
    Name = "assignment4-vpc-peering-accepter"
  }
}

# Route from Custom VPC to Default VPC
resource "aws_route" "custom_to_default" {
  route_table_id         = aws_route_table.public.id # Replace with appropriate route table
  destination_cidr_block = "172.31.0.0/16" # Replace with Default VPC CIDR block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Route from Default VPC to Custom VPC
resource "aws_route" "default_to_custom" {
  route_table_id         = "rtb-04dbbcf2fcbc92b3f" # Replace with Default VPC Route Table ID
  destination_cidr_block = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.vpc_peering.id
}
