#!/bin/bash
# Create ECR repositories and IAM roles/users.
# Run once — these persist across environment up/down cycles.
set -e

cd "$(dirname "$0")"

echo "🏗️  Setting up ECR repositories and IAM..."
terraform init -upgrade
terraform apply -auto-approve

echo ""
echo "✅ ECR ready!"
echo ""
echo "════════════════════════════════════════════"
echo " Add these as GitHub Actions secrets:"
echo "════════════════════════════════════════════"
echo " AWS_ACCESS_KEY_ID:"
terraform output -raw github_actions_access_key_id
echo ""
echo " AWS_SECRET_ACCESS_KEY:"
terraform output -raw github_actions_secret_access_key
echo ""
echo "════════════════════════════════════════════"
echo " GitHub repo → Settings → Secrets → Actions"
echo "════════════════════════════════════════════"
