

variable "aws_access_key" {
    default = "" # your access key goes here
}
variable "aws_secret_key" {

    default = "" #your secret key goes here
}
variable "aws_region" {
    description = "EC2 Region for the VPC"
    default = "ca-central-1"
}


variable "aws_region1" {
   
    default = "ca-central-1a"
}


variable "aws_region2" {
   
    default = "ca-central-1b"
}
variable "ami" {
    description = "AMI by region"
    default =  "ami-02e44367276fe7adc" # ubuntu 
    
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}
variable "cidr_blocks"{
    default= "0.0.0.0/0"
}

variable "public_subnet_cidr1" {
    description = "CIDR for the Public Subnet"
    default = "10.0.1.0/24"
}
variable "public_subnet_cidr2" {
    description = "CIDR for the Public Subnet"
    default = "10.0.2.0/24"
}

variable "private_subnet_cidr1" {
    description = "CIDR for the Private Subnet"
    default = "10.0.6.0/24"
}

variable "private_subnet_cidr2" {
    description = "CIDR for the Private Subnet"
    default = "10.0.7.0/24"
}