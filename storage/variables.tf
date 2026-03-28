variable "aws_region" {
  description = "AWS region — must match the region used in the root module"
  type        = string
  default     = "ap-southeast-1"
}

variable "volume_size_gb" {
  description = "Size of the MySQL data EBS volume in GB"
  type        = number
  default     = 20
}
