#!/bin/bash
# Destroy ECR repositories and IAM role.
# WARNING: this deletes all stored images. Only run if you want to wipe ECR completely.
set -e

cd "$(dirname "$0")"

echo "⚠️  WARNING: This will delete all ECR repositories and stored images."
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

# ECR repos must be empty before destroy — force-delete all images first
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-southeast-1")

for repo in restaurant/backend restaurant/frontend; do
  echo "==> Purging images in $repo..."
  IMAGE_IDS=$(aws ecr list-images --region "$AWS_REGION" --repository-name "$repo" \
    --query 'imageIds[*]' --output json 2>/dev/null || echo "[]")

  if [ "$IMAGE_IDS" != "[]" ] && [ -n "$IMAGE_IDS" ]; then
    aws ecr batch-delete-image --region "$AWS_REGION" \
      --repository-name "$repo" \
      --image-ids "$IMAGE_IDS" > /dev/null
  fi
done

echo "🛑 Destroying ECR infrastructure..."
terraform destroy -auto-approve

echo ""
echo "✅ ECR torn down."
