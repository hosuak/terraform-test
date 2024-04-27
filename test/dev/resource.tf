resource "aws_instance" "test-ec2" {
  ami = "ami-0e6f2b2fa0ca704d0"
  instance_type ="t2.micro"
  subnet_id = aws_subnet.dev-2a-public-subnet.id

  key_name = aws_key_pair.test_keypair.key_name
}

resource "tls_private_key" "sua_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "test_keypair" { 
    key_name = "sua_key.pem"
    public_key = tls_private_key.sua_key.public_key_openssh
}

resource "local_file" "sua_key" {
    filename = "./.ssh/sua-key.pem"
    content = tls_private_key.sua_key.private_key_pem
    file_permission = "0400"
 }