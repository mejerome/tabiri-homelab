resource "aws_vpc" "syslog_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true

  tags = {
    Name = "syslog_vpc"
    Purpose = "home-lab"
  }
}

resource "aws_subnet" "public" {
  count = 1
  vpc_id = aws_vpc.syslog_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = "us-east-1a" # Adjust as needed

  tags = {
    Name = "public-subnet-${count.index}"
    Purpose = "home-lab"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.syslog_vpc.id

  tags = {
    Name = "syslog_igw"
    Purpose = "home-lab"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.syslog_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
    Purpose = "home-lab"
  }
}

resource "aws_route_table_association" "public" {
  count = 1
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

