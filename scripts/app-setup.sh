#!/bin/bash
# Minimal app server bootstrap — just ensures the server is reachable.
# All software installation and deployment is handled by the local deploy.sh.
apt-get update -y -qq

# Add 2 GB swap to prevent OOM crashes on t3.micro (1 GB RAM)
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  # Reduce swap aggressiveness — only use swap when RAM is nearly full
  echo 'vm.swappiness=10' >> /etc/sysctl.conf
  sysctl -p
fi

echo "Server ready at $(date)" >> /var/log/restaurant-setup.log
