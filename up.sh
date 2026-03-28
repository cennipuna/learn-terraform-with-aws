#!/bin/bash
# Spin up the restaurant environment and deploy the app
set -e

SCRIPT_DIR="$(dirname "$0")"

echo "🚀 Starting restaurant environment..."
terraform apply -auto-approve

echo ""
echo "🐳 Deploying application..."
"$SCRIPT_DIR/deploy.sh"
