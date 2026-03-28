#!/bin/bash
# MySQL Server Setup — mounts the persistent EBS volume before starting MySQL
# Terraform templatefile variables: db_name, db_user, db_password
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y mysql-server

# ── Mount the persistent EBS volume ──────────────────────────────────────────
# On Nitro-based t3 instances, /dev/xvdf appears as /dev/nvme1n1
# Wait up to 2 minutes for the volume to be attached
EBS_DEVICE=""
for i in $(seq 1 60); do
  for dev in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
    if [ -b "$dev" ]; then
      EBS_DEVICE="$dev"
      break 2
    fi
  done
  sleep 2
done

if [ -z "$EBS_DEVICE" ]; then
  echo "ERROR: EBS data volume did not attach within 2 minutes." >> /var/log/restaurant-setup.log
  exit 1
fi

echo "EBS device found: $EBS_DEVICE" >> /var/log/restaurant-setup.log

# Stop MySQL before touching the data directory
systemctl stop mysql

# Format the volume only if it has no filesystem (very first boot only)
if ! blkid "$EBS_DEVICE" > /dev/null 2>&1; then
  echo "New volume — formatting and seeding with MySQL defaults..." >> /var/log/restaurant-setup.log
  mkfs.ext4 "$EBS_DEVICE"
  mkdir -p /mnt/mysql-ebs
  mount "$EBS_DEVICE" /mnt/mysql-ebs
  rsync -a /var/lib/mysql/ /mnt/mysql-ebs/
  umount /mnt/mysql-ebs
fi

# Mount EBS as the MySQL data directory
mount "$EBS_DEVICE" /var/lib/mysql

# Persist the mount across reboots
echo "$EBS_DEVICE /var/lib/mysql ext4 defaults,nofail 0 2" >> /etc/fstab

# Allow remote connections (security group restricts to app server only)
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i 's/^mysqlx-bind-address\s*=.*/mysqlx-bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl enable mysql
systemctl start mysql

# Create DB and user only if they don't exist (safe to re-run across up/down cycles)
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ${db_name}
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${db_user}'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'%';
FLUSH PRIVILEGES;
SQL

echo "MySQL setup complete at $(date)" >> /var/log/restaurant-setup.log
