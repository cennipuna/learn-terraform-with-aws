# ── MySQL Server ─────────────────────────────────────────────────────────────
resource "aws_instance" "db" {
  ami                    = var.ami_id
  instance_type          = var.db_instance_type
  key_name               = aws_key_pair.restaurant.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.db.id]
  iam_instance_profile   = var.ec2_instance_profile != "" ? var.ec2_instance_profile : null

  # Must be in the same AZ as the EBS volume
  availability_zone = "${var.aws_region}a"

  user_data = templatefile("${path.module}/scripts/mysql-setup.sh", {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "restaurant-db"
    Role = "database"
  }
}

# Attach the persistent EBS volume as /dev/xvdf on the DB server
# On t3 (Nitro) instances this appears in the OS as /dev/nvme1n1
resource "aws_volume_attachment" "mysql_data" {
  device_name  = "/dev/xvdf"
  volume_id    = var.mysql_data_volume_id
  instance_id  = aws_instance.db.id
  force_detach = true
}

# ── App Server (Docker: Nginx + PHP-FPM + Redis + Reverb + Queue) ─────────────
resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.app_instance_type
  key_name               = aws_key_pair.restaurant.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = var.ec2_instance_profile != "" ? var.ec2_instance_profile : null

  # Pass the DB server's private IP at provision time
  user_data = templatefile("${path.module}/scripts/app-setup.sh", {
    db_host     = aws_instance.db.private_ip
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "restaurant-app"
    Role = "application"
  }

  depends_on = [aws_instance.db]
}
