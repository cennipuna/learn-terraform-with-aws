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

# ── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "restaurant" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "restaurant-vpc" }
}

# Public subnet — both servers live here (MySQL restricted by SG, not subnet)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.restaurant.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "restaurant-public-subnet" }
}

resource "aws_internet_gateway" "restaurant" {
  vpc_id = aws_vpc.restaurant.id
  tags   = { Name = "restaurant-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.restaurant.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.restaurant.id
  }

  tags = { Name = "restaurant-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── SSH Key Pair ──────────────────────────────────────────────────────────────
resource "aws_key_pair" "restaurant" {
  key_name   = "restaurant-key-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  public_key = var.ssh_public_key

  lifecycle {
    ignore_changes = [key_name]
  }
}

