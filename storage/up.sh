#!/bin/bash
# Create the persistent EBS volume for MySQL data and S3 media bucket.
# Run once — these survive environment up/down cycles.
set -e

cd "$(dirname "$0")"

echo "💾 Creating MySQL data volume and S3 media bucket..."
terraform init -upgrade
terraform apply -auto-approve

echo ""
echo "✅ Persistent storage created!"
echo ""
VOLUME_ID=$(terraform output -raw volume_id)
echo "Add this to your root terraform.tfvars:"
echo "  mysql_data_volume_id = \"$VOLUME_ID\""
echo ""
echo "S3 media bucket:"
echo "  Name: $(terraform output -raw s3_bucket_name)"
echo "  URL:  $(terraform output -raw s3_bucket_url)"
echo ""
echo "deploy.sh picks up the bucket automatically — no manual tfvars step needed."
