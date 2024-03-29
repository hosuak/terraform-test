resource "aws_vpc" "test-vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "test-2a-public-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-2a-public-vpc"
  }
}

resource "aws_subnet" "test-2c-public-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "test-2c-public-vpc"
  }
}

resource "aws_subnet" "test-2a-private-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = "ap-northeast-2a"  

  tags = {
    Name = "test-2a-private-vpc"
  }
}

resource "aws_subnet" "test-2c-private-subnet" {
  vpc_id     = aws_vpc.test-vpc.id
  cidr_block = "172.16.20.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "test-2c-private-vpc"
  }
}

resource "aws_internet_gateway" "test-gw" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "test-gw"
  }
}

resource "aws_eip" "nat-2a" {               # 공인ip 할당
  domain = "vpc"                            # 현재 vpc에서 eip를 사용할 것인지
}

resource "aws_nat_gateway" "test-nat-gw" {
  allocation_id = aws_eip.nat-2a.id
  subnet_id     = aws_subnet.test-2c-public-subnet.id

  tags = {
    Name = "gw-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.test-gw]                # ig 생성 후 nat 생성
}

resource "aws_route_table" "test-public-rt" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"            # internet gateway
    gateway_id = "aws_internet_gateway.test-gw.id"
  }
  
  route {
    cidr_block = "172.16.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "test-public-rt"
  }
}

resource "aws_route_table" "test-private-rt" {
  vpc_id = aws_vpc.test-vpc.id

  route{
    cidr_block = "0.0.0.0/0"            # Nat gateway
  }

  route {
    cidr_block = "172.16.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "test-private-rt"
  }
}

resource "aws_route_table_association" "test-2a-public" {
  subnet_id      = aws_subnet.test-2a-public-subnet.id
  route_table_id = aws_route_table.test-public-rt.id
}

resource "aws_route_table_association" "test-2c-public" {
  subnet_id      = aws_subnet.test-2c-public-subnet.id
  route_table_id = aws_route_table.test-public-rt.id
}

resource "aws_route_table_association" "test-2a-private" {
  subnet_id      = aws_subnet.test-2a-private-subnet.id
  route_table_id = aws_route_table.test-private-rt.id
}

resource "aws_route_table_association" "test-2c-private" {
  subnet_id      = aws_subnet.test-2c-private-subnet.id
  route_table_id = aws_route_table.test-private-rt.id
}

resource "aws_security_group" "test-nat-sg" {
  name = "test-nat-sg"
  description = "Security group for NAT Gateway"
  vpc_id = aws_vpc.test-vpc.id

  # Inbound traffic rule - Allow HTTPS traffic (443 port)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "nat-sg"
  }
}
resource "aws_security_group" "test-web-sg" {
  name = "test-sg"
  description = "Terraform web-test sg"
  vpc_id = aws_vpc.test-vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "https"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 22
    to_port     = 22
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
    description = "WEB from ALL NETWORK"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "ICMP from ALL NETWORK"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "test-web-sg"
  }
}