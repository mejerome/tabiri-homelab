provider "aws" {
  region = "us-east-1"
  profile = "default"
}

data "aws_availability_zones" "this" {}

resource "aws_vpc" "airflow" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "airflow-vpc"
  }
}

resource "aws_internet_gateway" "airflow" {
  vpc_id = aws_vpc.airflow.id

  tags = {
    Name = "airflow-igw"
  }
}

// Public Subnet and Route Table
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.airflow.id
  cidr_block = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ][count.index]
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.this.names[count.index]


  tags = {
    Name = "airflow-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.airflow.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow.id
  }

  tags = {
    Name = "airflow-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public[0].id
  route_table_id = aws_route_table.public.id
}

// Private Subnet and Route Table
resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.airflow.id
  cidr_block = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ][count.index]
  map_public_ip_on_launch = false
  availability_zone = data.aws_availability_zones.this.names[count.index]

  tags = {
    Name = "airflow-private-subnet"
  }
}

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.airflow.default_route_table_id

  tags = {
    Name = "airflow-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_default_route_table.private.id
  count = 2
  subnet_id = aws_subnet.private[count.index].id
}