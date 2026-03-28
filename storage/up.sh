#!/bin/bash
# Create the persistent EBS volume for MySQL data.
# Run once — this survives environment up/down cycles.
set -e

cd "$(dirname "$0")"

echo "💾 Creating MySQL data volume..."
terraform init -upgrade
terraform apply -auto-approve

echo ""
echo "✅ EBS volume created!"
echo ""
VOLUME_ID=$(terraform output -raw volume_id)
echo "Add this to your root terraform.tfvars:"
echo "  mysql_data_volume_id = \"$VOLUME_ID\""
