#!/bin/bash
# Minimal app server bootstrap — just ensures the server is reachable.
# All software installation and deployment is handled by the local deploy.sh.
apt-get update -y -qq
echo "Server ready at $(date)" >> /var/log/restaurant-setup.log
