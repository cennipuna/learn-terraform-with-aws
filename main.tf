terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Security Group to allow SSH, HTTP, HTTPS, and custom port 8089
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-security-group"
  description = "Allow SSH, HTTP, HTTPS, and port 8089"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Nginx on Docker"
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# EC2 Key Pair (you'll need to create this manually or provide existing key name)
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  public_key = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [key_name]
  }
}

# EC2 Instance with Docker and Nginx
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              
              # Add ubuntu user to docker group
              usermod -a -G docker ubuntu
              
              # Run Nginx container on port 8089
              docker run -d -p 8089:80 --name nginx-server --restart always nginx:latest
              
              EOF

  tags = {
    Name = "terraform-docker-nginx"
  }
}

