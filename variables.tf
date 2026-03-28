variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

# Ubuntu 22.04 LTS in ap-southeast-1
variable "ami_id" {
  description = "AMI ID (Ubuntu 22.04 LTS) for EC2 instances"
  type        = string
  default     = "ami-01811d4912b4ccb26"
}

variable "app_instance_type" {
  description = "EC2 instance type for the app server (Nginx, PHP-FPM, Redis, Reverb, Queue, Vue)"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "EC2 instance type for the MySQL database server"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access"
  type        = string
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "restaurant_pos"
}

variable "db_user" {
  description = "MySQL application user"
  type        = string
  default     = "restaurant"
}

variable "db_password" {
  description = "MySQL application user password"
  type        = string
  sensitive   = true
}

variable "ec2_instance_profile" {
  description = "IAM instance profile name for ECR pull access (output of ecr/up.sh). Leave empty to skip."
  type        = string
  default     = ""
}

variable "mysql_data_volume_id" {
  description = "EBS volume ID for MySQL data persistence (output of storage/up.sh). Run storage/up.sh first."
  type        = string

  validation {
    condition     = can(regex("^vol-[0-9a-f]+$", var.mysql_data_volume_id))
    error_message = "mysql_data_volume_id must be a valid EBS volume ID (e.g. vol-0abc123def456789). Run storage/up.sh first and paste the volume_id output into terraform.tfvars."
  }
}

