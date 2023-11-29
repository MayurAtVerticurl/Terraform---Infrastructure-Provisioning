provider "aws" {
  region                   = "us-east-2"
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_instance" "this" {
  ami                     = "ami-089c26792dcb1fbd4"
  instance_type           = var.instance_type
  key_name                = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_port.id]
  subnet_id               = aws_subnet.publicsubnet2a.id
    user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y &&
              sudo apt install -y nginx
              echo "Instance Created by Mayur using Terraform" > /var/www/html/index.html
              EOF

  tags = {
    Name = "mayInstanceFromTerra"
  }
}

resource "aws_security_group" "allow_port" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "mayVPC"
  }
}

resource "aws_subnet" "publicsubnet2a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "mayur-public-subnet-1"
  }
}

resource "aws_subnet" "publicsubnet2b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "mayur-public-subnet-2"
  }
}

resource "aws_subnet" "publicsubnet2c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "mayur-public-subnet-3"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

    route {
        cidr_block = "10.0.1.0/24"
        gateway_id = aws_internet_gateway.gw.id
    }

  tags = {
    Name = "mayur-public_route_table"
  }
}

resource "aws_route_table_association" "public_route_table_2a_association" {
  subnet_id      = aws_subnet.publicsubnet2a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_2b_association" {
  subnet_id      = aws_subnet.publicsubnet2b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_2c_association" {
  subnet_id      = aws_subnet.publicsubnet2c.id
  route_table_id = aws_route_table.public_route_table.id  
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mayur-internet-gateway"
  }
}

resource "aws_route" "mayur_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}