variable "region" {
    default = "us-east-1"
}

variable "vpc_cidr" {
    type        = string
    description = "The IP range to use for the VPC"
    default     = "10.0.0.0/16"
}

variable "public_subnet_number_1a" {
    type = string
    description = "Public subnet cidr"
    default = "10.0.64.0/19"
}

variable "public_subnet_number_1b" {
    type = string
    description = "Public subnet cidr"
    default = "10.0.96.0/19"
}

variable "private_subnet_number_1a" {
    type = string
    description = "Private subnet cidr"
    default = "10.0.0.0/19"
}

variable "private_subnet_number_1b" {
    type = string
    description = "Private subnet cidr"
    default = "10.0.32.0/19"
}