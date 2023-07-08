#create vpc
resource "aws_vpc" "example" {
    cidr_block = "10.0.0.0/16"
    tags = {
        "Name"= "test"
        project= "sprints"
    }
}
#create public subnet
resource "aws_subnet" "public-subnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.example.id
    map_public_ip_on_launch = true
     tags = {
        Name = "public-subnet"
    }
}
#create Internet gateway
resource "aws_internet_gateway" "IGW-vpc" {
  vpc_id = aws_vpc.example.id
    tags = {
    Name = "IGW-vpc"
  }
}
#create routing table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-vpc.id
  }
   tags = {
    Name = "route-table"
  }
}
#association the route table with the public subnet
resource "aws_route_table_association" "route-table-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route-table.id
}
# Create a security group
resource "aws_security_group" "security-group" {
  name        = "security-group"
  description = "Allow HTTP and SSH traffic"

  vpc_id = aws_vpc.example.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
   tags = {
    Name = "security-group"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "ec2-instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.security-group.id]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y apache2
  EOF
  
  tags = { 
    Name = "ec2-instance" 
    }
}


