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

# ── EBS Volume for MySQL data ─────────────────────────────────────────────────
# This persists across environment up/down cycles.
# The EC2 DB server attaches this volume on boot and mounts it as /var/lib/mysql.
resource "aws_ebs_volume" "mysql_data" {
  availability_zone = "${var.aws_region}a"
  size              = var.volume_size_gb
  type              = "gp3"

  tags = {
    Name = "restaurant-mysql-data"
  }
}
