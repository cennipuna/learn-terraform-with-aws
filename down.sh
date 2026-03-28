#!/bin/bash
# Tear down the restaurant environment
set -e

echo "🛑 Destroying restaurant environment..."
terraform destroy -auto-approve

echo ""
echo "✅ Environment torn down. All AWS resources have been deleted."
