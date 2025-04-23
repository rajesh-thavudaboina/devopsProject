# VPC
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "dpp-vpc"
  }
}

resource "aws_subnet" "dpp-public-subnet-01" {
  vpc_id     = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.1.0/24"
  tags = {
    Name = "dpp-public-subnet-01"
  }
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
}
resource "aws_subnet" "dpp-public-subnet-02" {
  vpc_id     = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.2.0/24"
  tags = {
    Name = "dpp-public-subnet-02"
  }
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id
  tags = {
    Name = "dpp-igw"
  }
}
resource "aws_route_table" "dpp-public-rt" {
  vpc_id = aws_vpc.dpp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }
}

resource "aws_route_table_association" "dpp-rta-public-subnet-01" {
  subnet_id      = aws_subnet.dpp-public-subnet-01.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

resource "aws_route_table_association" "dpp-rta-public-subnet-02" {
  subnet_id      = aws_subnet.dpp-public-subnet-02.id
  route_table_id = aws_route_table.dpp-public-rt.id
}

resource "aws_security_group" "dpp-sg" {
  name   = "dpp-sg"
  vpc_id = aws_vpc.dpp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  tags = {
    Name = "dpp-sg"
  }
}

resource "aws_instance" "dpp-server" {
  ami                    = "ami-0e35ddab05955cf57"
  instance_type          = "t2.medium"
  key_name               = "devops"
  vpc_security_group_ids = [aws_security_group.dpp-sg.id]
  subnet_id              = aws_subnet.dpp-public-subnet-01.id
  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 20
  }
  for_each = toset(["jenkins-master", "build-slave", "ansible-server"])
  tags = {
    Name = "${each.key}"
  }
}