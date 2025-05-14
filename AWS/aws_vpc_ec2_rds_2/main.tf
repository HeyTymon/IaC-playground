provider "aws" {
    region     = "eu-north-1"
    access_key = var.access_key
    secret_key = var.secret_key
}

resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr
  
  tags = {
    Name = "project-3-main-vpc"
  }
}

resource "aws_subnet" "private_subnets" {
    count      = length(var.private_subnets)
    
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = element(var.private_subnets, count.index)
    availability_zone = element(var.az, count.index)

    tags = {
      Name = "project-3-private-${count.index + 1}"
    }
}

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnets)

    vpc_id =  aws_vpc.main_vpc.id
    cidr_block = element(var.public_subnets,count.index)
    availability_zone = element(var.az, count.index)

    tags = {
      Name = "project-3-public-${count.index + 1}"
    }
}

resource "aws_internet_gateway" "main_ig" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
      Name = "project-3-ig"
    }
}

resource "aws_eip" "nat_eip" {
    count  = length(var.private_subnets)
    domain = "vpc"
}

resource "aws_nat_gateway" "main_nat_gateway" {
    count         = length(var.private_subnets)

    depends_on    = [aws_eip.nat_eip]
    allocation_id = aws_eip.nat_eip[count.index].id
    subnet_id     = aws_subnet.private_subnets[count.index].id

    tags = {
        Name = "project-3-nat-${count.index + 1}"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = var.default_route
        gateway_id = aws_internet_gateway.main_ig.id
    }

    tags = {
      Name = "project-3-public-rt"
    }
}

resource "aws_route_table" "private_rt" {
    count      = length(var.private_subnets)

    vpc_id     = aws_vpc.main_vpc.id
    depends_on = [aws_nat_gateway.main_nat_gateway]

    route {
        cidr_block     = var.default_route
        nat_gateway_id = aws_nat_gateway.main_nat_gateway[count.index].id
    }

    tags = {
        Name = "project-3-private-rt-${count.index + 1}"
    }
}

resource "aws_route_table_association" "public_subnet_association" {
    count          = length(var.public_subnets)

    depends_on = [aws_subnet.public_subnets, aws_route_table.public_rt]
    subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_association" {
    count          = length(var.private_subnets)

    depends_on = [aws_subnet.private_subnets, aws_route_table.private_rt]
    subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
    route_table_id = aws_route_table.private_rt[count.index].id
}

output "public_ip_1" {
    value = aws_eip.nat_eip[0].public_ip
}

output "public_ip_2" {
    value = aws_eip.nat_eip[1].public_ip
}

resource "aws_instance" "ec2_instance_1" {
    ami                    = var.ami
    instance_type          = var.inst_type
    subnet_id              = aws_subnet.public_subnets[0].id
    vpc_security_group_ids = [aws_security_group.instance_1_sg.id]
    key_name               = var.key_pair

    tags = {
        Name = "project-3-instance-1"
    }
}

resource "aws_security_group" "instance_1_sg" {
    vpc_id = aws_vpc.main_vpc.id

    ingress  {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
    }   

    ingress  {
        cidr_blocks = ["0.0.0.0/0"]
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "project-3-sg-1"
    }
}    
