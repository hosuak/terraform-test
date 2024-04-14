resource "aws_vpc" "dev-vpc" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "dev-2a-public-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-2a-public-vpc"
  }
}

resource "aws_subnet" "dev-2c-public-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-2c-public-vpc"
  }
}

resource "aws_subnet" "dev-2a-private-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = "ap-northeast-2a"  

  tags = {
    Name = "dev-2a-private-vpc"
  }
}

resource "aws_subnet" "dev-2c-private-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "172.16.20.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "dev-2c-private-vpc"
  }
}

resource "aws_internet_gateway" "dev-gw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "dev-gw"
  }
}

resource "aws_eip" "nat-2a" {               # 공인ip 할당
  domain = "vpc"                            # 현재 vpc에서 eip를 사용할 것인지
}

resource "aws_nat_gateway" "dev-nat-gw" {
  allocation_id = aws_eip.nat-2a.id
  subnet_id     = aws_subnet.dev-2c-public-subnet.id

  tags = {
    Name = "gw-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.dev-gw]                # ig 생성 후 nat 생성
}

resource "aws_route_table" "dev-public-rt" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"            # internet gateway
    gateway_id = "aws_internet_gateway.dev-gw.id"
  }
  
  route {
    cidr_block = "172.16.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route_table" "dev-private-rt" {  ## 네트워크 인터페이스 추가 : nat instance
  vpc_id = aws_vpc.dev-vpc.id

  route{
    cidr_block = "0.0.0.0/0"            # Nat gateway
  }

  route {
    cidr_block = "172.16.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name = "dev-private-rt"
  }
}

resource "aws_route_table_association" "dev-2a-public" {
  subnet_id      = aws_subnet.dev-2a-public-subnet.id
  route_table_id = aws_route_table.dev-public-rt.id
}

resource "aws_route_table_association" "dev-2c-public" {
  subnet_id      = aws_subnet.dev-2c-public-subnet.id
  route_table_id = aws_route_table.dev-public-rt.id
}

resource "aws_route_table_association" "dev-2a-private" {
  subnet_id      = aws_subnet.dev-2a-private-subnet.id
  route_table_id = aws_route_table.dev-private-rt.id
}

resource "aws_route_table_association" "dev-2c-private" {
  subnet_id      = aws_subnet.dev-2c-private-subnet.id
  route_table_id = aws_route_table.dev-private-rt.id
}

resource "aws_security_group" "dev-nat-sg" {
  name = "dev-nat-sg"
  description = "Security group for NAT Gateway"
  vpc_id = aws_vpc.dev-vpc.id

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
resource "aws_security_group" "dev-web-sg" {
  name = "dev-sg"
  description = "Terraform web-dev sg"
  vpc_id = aws_vpc.dev-vpc.id

# https, ssh, 
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
    ingress {     #icmp 없으면 트러블슈팅을 못해
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
    Name = "dev-web-sg"
  }
}

