provider "aws" {
  region = "us-east-1"  # Change this to your preferred AWS region
}

# Create a VPC
resource "aws_vpc" "springboot_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a Subnet
resource "aws_subnet" "springboot_subnet" {
  vpc_id            = aws_vpc.springboot_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"  # Change this based on your AWS region
}

# Internet Gateway
resource "aws_internet_gateway" "springboot_gw" {
  vpc_id = aws_vpc.springboot_vpc.id
}

# Route Table
resource "aws_route_table" "springboot_rt" {
  vpc_id = aws_vpc.springboot_vpc.id
}

# Add Route to the Internet
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.springboot_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.springboot_gw.id
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "springboot_rta" {
  subnet_id      = aws_subnet.springboot_subnet.id
  route_table_id = aws_route_table.springboot_rt.id
}

# Security Group to Allow HTTP & SSH
resource "aws_security_group" "springboot_sg" {
  vpc_id      = aws_vpc.springboot_vpc.id
  name        = "springboot-sg"
  description = "Allow SSH and HTTP traffic"

  # Allow SSH (22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (Restrict in production)
  }

  # Allow HTTP (80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP access
  }

  # Allow Application Port (8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow Public Access to Spring Boot App
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "springboot_ec2" {
  ami                    = "ami-085ad6ae776d8f09c"  # Change to the latest Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.springboot_subnet.id
  vpc_security_group_ids = [aws_security_group.springboot_sg.id]

  # Bootstrap script to install Java 17 and Git
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install java-17-amazon-corretto -y
              sudo yum install git -y
              EOF

  tags = {
    Name = "SpringBootApp"
  }
}

# Elastic IP (Keeps EC2 Public IP Static)
resource "aws_eip" "springboot_eip" {
  instance = aws_instance.springboot_ec2.id
}

# Outputs
output "instance_ip" {
  value = aws_instance.springboot_ec2.public_ip
}
output "elastic_ip" {
  value = aws_eip.springboot_eip.public_ip
}
