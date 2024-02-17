# Create public and private subnets
resource "aws_subnet" "public_subnet_1a" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.public_subnet_number_1a
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_subnet_1b" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.public_subnet_number_1b
    availability_zone = "us-east-1b"
}

resource "aws_subnet" "private_subnet_1a" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.private_subnet_number_1a
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_1b" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.private_subnet_number_1b
    availability_zone = "us-east-1b"
}

# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr}"

    tags = {
        Name = "ianjaffe-vpc"
    }
}
