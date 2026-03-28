#!/bin/bash
# Build Docker images from the restaurant-pos-poc project and push to ECR.
# Usage:  ./push.sh [tag]          (default tag: latest)
#         ./push.sh v1.2.3         (tag a specific release)
set -e

cd "$(dirname "$0")"

TAG=${1:-latest}
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "ap-southeast-1")
BACKEND_URL=$(terraform output -raw backend_repo_url)
FRONTEND_URL=$(terraform output -raw frontend_repo_url)
NGINX_URL=$(terraform output -raw nginx_repo_url)
REGISTRY_ID=$(terraform output -raw registry_id)

# Default to the sibling restaurant-pos-poc directory; override with REPO_DIR env var
APP_DIR=${REPO_DIR:-"$(dirname "$0")/../../restaurant-pos-poc"}

if [ ! -d "$APP_DIR" ]; then
  echo "❌ Cannot find restaurant-pos-poc at: $APP_DIR"
  echo "   Set REPO_DIR=/path/to/restaurant-pos-poc and retry."
  exit 1
fi

echo "==> Logging into ECR ($AWS_REGION)..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
  "$REGISTRY_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# ── Backend ───────────────────────────────────────────────────────────────────
echo ""
echo "==> Building backend image (tag: $TAG)..."
docker build -t "restaurant-backend:$TAG" "$APP_DIR/backend"
docker tag "restaurant-backend:$TAG" "$BACKEND_URL:$TAG"
docker push "$BACKEND_URL:$TAG"

# Also tag as 'latest' if pushing a versioned tag
if [ "$TAG" != "latest" ]; then
  docker tag "restaurant-backend:$TAG" "$BACKEND_URL:latest"
  docker push "$BACKEND_URL:latest"
fi

# ── Frontend ──────────────────────────────────────────────────────────────────
echo ""
echo "==> Building frontend image (tag: $TAG)..."
docker build -t "restaurant-frontend:$TAG" "$APP_DIR/frontend"
docker tag "restaurant-frontend:$TAG" "$FRONTEND_URL:$TAG"
docker push "$FRONTEND_URL:$TAG"

if [ "$TAG" != "latest" ]; then
  docker tag "restaurant-frontend:$TAG" "$FRONTEND_URL:latest"
  docker push "$FRONTEND_URL:latest"
fi

# ── Nginx ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Building nginx image (tag: $TAG)..."
docker build -t "restaurant-nginx:$TAG" "$APP_DIR/docker/nginx" -f "$APP_DIR/docker/nginx/Dockerfile.prod"
docker tag "restaurant-nginx:$TAG" "$NGINX_URL:$TAG"
docker push "$NGINX_URL:$TAG"

if [ "$TAG" != "latest" ]; then
  docker tag "restaurant-nginx:$TAG" "$NGINX_URL:latest"
  docker push "$NGINX_URL:latest"
fi

echo ""
echo "✅ Images pushed:"
echo "   $BACKEND_URL:$TAG"
echo "   $FRONTEND_URL:$TAG"
echo "   $NGINX_URL:$TAG"
