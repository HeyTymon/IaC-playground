variable "vpc_cidr" {
    default = "10.0.0.0/16"
    type    = string
}

variable "access_key" {
    description = "AWS Access Key"
    type        = string
}

variable "secret_key" {
    description = "AWS Secret Key"
    type        = string
}

variable "public_subnets" {
    default = ["10.0.1.0/24","10.0.2.0/24"]
    type    = list(string)
}

variable "private_subnets" {
    default = ["10.0.11.0/24","10.0.12.0/24"]
    type    = list(string)
}

variable "az" {
    default = ["eu-north-1a","eu-north-1b"]
    type    = list(string)
}

variable "default_route" {
    default = "0.0.0.0/0"
    type    = string
}

variable "ami" {
    default = "ami-0548d28d4f7ec72c5"
    type    = string
}

variable "inst_type" {
    default = "t3.micro"
    type    = string
}

variable "key_pair" {
    default = "key-project-3"
    type = string
}
