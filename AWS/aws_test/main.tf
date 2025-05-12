provider "aws" {
  region = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "secret_key" {
  description = "AWS Secret Key"
  type        = string
}

resource "aws_vpc" "test_vpc" { 
 cidr_block = "192.168.0.0/16"
 tags = {
  Name = "test-vpc-1"
 }
}

resource "aws_internet_gateway" "test_gw" {
 vpc_id = aws_vpc.test_vpc.id
}

resource "aws_subnet" "test_subnet" { 
 vpc_id = aws_vpc.test_vpc.id
 cidr_block = "192.168.1.0/24"
 availability_zone = "eu-north-1a"
 tags = { 
  Name = "test-subnet-1"
 }
}

resource "aws_route_table" "test_rt" { 
 vpc_id = aws_vpc.test_vpc.id
 
 route { 
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.test_gw.id
 }

 tags = { 
  Name = "test-rt"
 } 
}

resource "aws_route_table_association" "test_a" { 
 subnet_id = aws_subnet.test_subnet.id
 route_table_id = aws_route_table.test_rt.id
}

resource "aws_security_group" "test_sg" {
  name        = "web_sg"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test_sg"
  }
}

resource "aws_network_interface" "test_int" {
 subnet_id = aws_subnet.test_subnet.id
 private_ips = ["192.168.1.100"]
 security_groups = [aws_security_group.test_sg.id]

 attachment {
  instance = aws_instance.test_instance.id
  device_index = 1
 }
}

resource "aws_eip" "public_ip" {
 vpc = true
 network_interface = aws_network_interface.test_int.id
 associate_with_private_ip = "192.168.1.100"
 depends_on = [aws_internet_gateway.test_gw]
}

resource "aws_instance" "test_instance" {
 ami = "ami-0dd574ef87b79ac6c"
 instance_type = "t3.micro"
 tags = { 
  Name = "test-instance"
 } 
}

