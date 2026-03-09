variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-01811d4912b4ccb26" # Amazon Linux 2023 in ap-southeast-1
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}
