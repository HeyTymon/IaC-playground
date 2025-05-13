provider "aws" {
  region = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# ---- Variables ----

variable "access_key" {
  description = "AWS Access Key"
  type = string
}

variable "secret_key" {
 description = "AWS Secret Key"
 type = string
}

variable "ami_id_1" {
 description = "AMI for EC2"
 type = string
 default = "ami-0548d28d4f7ec72c5"
}

variable "db_user" {
 description = "User for RDS database"
 type = string
}

variable "db_pass" {
 description = "Password for RDS database"
 type = string
}

# ---- Resources ----

resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
  Name = "project-2-main"
 }
}

resource "aws_subnet" "private" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "eu-north-1a"

 tags = {
  Name = "project2-private"
 }
}

resource "aws_subnet" "private-2" { 
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.2.0/24"
 availability_zone = "eu-north-1b"
}

resource "aws_subnet" "public" {
 vpc_id = aws_vpc.main.id
 cidr_block = "10.0.3.0/24"
 availability_zone = "eu-north-1a"
 map_public_ip_on_launch = true 

 tags = {
  Name = "project2-public"
 }
}

resource "aws_db_subnet_group" "rds_subnet" {
 name = "rds-subnet-group"
 subnet_ids = [aws_subnet.private.id, aws_subnet.private-2.id]

 tags = {
  Name = "rds-subnet-group"
 }
}

resource "aws_internet_gateway" "ig" {
 vpc_id = aws_vpc.main.id 
}

resource "aws_route_table" "rt" {
 vpc_id = aws_vpc.main.id
 
 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id 
 }
}

resource "aws_route_table_association" "rt_association" { 
 subnet_id = aws_subnet.public.id
 route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg_id_1" {
 name = "ec2-security-group"
 vpc_id = aws_vpc.main.id
 description = "Allow SSH and HTTP"

 ingress { 
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }

 ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }

 egress { 
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
 }

 tags = { 
  Name = "ec2-security-group"
 }
}

resource "aws_security_group" "sg_id_2" {
 name = "rds-security-group"
 vpc_id = aws_vpc.main.id
 description = "Security group for RDS instance"

 ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   cidr_blocks = ["10.0.1.0/24"] 
 }

 egress {
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
 }

 tags = {
   Name = "rds-security-group"
 }
}

resource "aws_instance" "ins-1" {
 ami = var.ami_id_1
 instance_type = "t3.micro"
 subnet_id = aws_subnet.public.id
 security_groups = [aws_security_group.sg_id_1.id]

 tags = {
  Name = "project-2-instance-1"
 }
}

resource "aws_db_instance" "rds_mysql" {
 allocated_storage = 10
 db_name = "project2db"
 engine = "mysql"
 engine_version = "8.0"
 instance_class = "db.t3.micro"
 username = var.db_user
 password = var.db_pass
 db_subnet_group_name = aws_db_subnet_group.rds_subnet.id 
 vpc_security_group_ids = [aws_security_group.sg_id_2.id]

 tags = {
  Name = "project-2-rds-1"
 }
}

resource "aws_eip" "eip-ins-1" {
 instance = aws_instance.ins-1.id 
}
