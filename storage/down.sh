#!/bin/bash
# Destroy the EBS volume — THIS PERMANENTLY DELETES ALL DATABASE DATA.
set -e

cd "$(dirname "$0")"

echo "⚠️  WARNING: This will permanently delete the MySQL EBS volume and ALL data."
read -p "Type 'delete-all-data' to confirm: " confirm
if [ "$confirm" != "delete-all-data" ]; then
  echo "Aborted."
  exit 0
fi

echo "🛑 Destroying EBS volume..."
terraform destroy -auto-approve

echo ""
echo "✅ EBS volume deleted."
