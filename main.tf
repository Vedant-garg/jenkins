provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "RDS-VPC"
  }
}

# Create Subnets in Two Different AZs
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "RDS-Subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "RDS-Subnet-2"
  }
}

# Create a DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  tags = {
    Name = "example-db-subnet-group"
  }
}

# Create an RDS Instance
resource "aws_db_instance" "postgresql" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13.15"
  instance_class         = "db.t3.micro"
  db_name                = "mydatabase"
  username               = "dbadmin"
  password               = "password123"
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "RDS-SG"
  }
}

# Allow inbound traffic to RDS (PostgreSQL)
resource "aws_security_group_rule" "allow_postgres" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # Change this to a specific CIDR block for better security
  security_group_id = aws_security_group.rds_sg.id
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.main.id # RDS VPC
  peer_vpc_id = "vpc-068c32f71d07ad405" # Replace with the Default VPC ID
  tags = {
    Name = "RDS-Default-VPC-Peering"
  }
}

# Route Table for RDS VPC
resource "aws_route_table" "rds_vpc_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "RDS-VPC-Route-Table"
  }
}

# Route for VPC Peering in RDS Route Table
resource "aws_route" "rds_vpc_peer_route" {
  route_table_id         = aws_route_table.rds_vpc_route_table.id
  destination_cidr_block = "172.31.0.0/16" # Replace with Default VPC CIDR block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Associate RDS Subnets with Route Table
resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.rds_vpc_route_table.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.rds_vpc_route_table.id
}



