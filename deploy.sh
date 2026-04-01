#!/bin/bash
# Deploy the restaurant app onto the app server.
# Fully self-contained — installs Docker/AWS CLI if needed, writes .env,
# copies docker-compose.prod.yml, logs into ECR and starts containers.
# Called automatically by up.sh — can also be run standalone to re-deploy.
set -e

TERRAFORM_DIR="$(dirname "$0")"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/terraform-key}"
REPO_DIR="${REPO_DIR:-$(dirname "$0")/../restaurant-pos-poc}"
COMPOSE_FILE="$REPO_DIR/docker-compose.prod.yml"
AWS_REGION="ap-southeast-1"

SSH="ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=10"
SCP="scp -i $SSH_KEY -o StrictHostKeyChecking=no"

# ── Get outputs from Terraform ────────────────────────────────────────────────
echo "🔍 Reading Terraform outputs..."
cd "$TERRAFORM_DIR"
APP_IP=$(terraform output -raw app_public_ip 2>/dev/null)
DB_IP=$(terraform output -raw db_private_ip 2>/dev/null)

if [ -z "$APP_IP" ]; then
  echo "❌ Could not get app_public_ip. Has ./up.sh been run?"
  exit 1
fi
echo "   App server: $APP_IP"
echo "   DB server:  $DB_IP"

# Read DB credentials — from terraform.tfvars, TF_VAR_* env vars, or prompt
tfvars_file="$TERRAFORM_DIR/terraform.tfvars"
read_tfvar() { grep -E "^\s*$1\s*=" "$tfvars_file" 2>/dev/null | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d '"' | xargs; }

DB_NAME=$(read_tfvar db_name)
DB_USER=$(read_tfvar db_user)
DB_PASS=$(read_tfvar db_password)

# Fall back to TF_VAR_* environment variables
DB_NAME="${DB_NAME:-${TF_VAR_db_name:-restaurant_pos}}"
DB_USER="${DB_USER:-${TF_VAR_db_user:-restaurant}}"
DB_PASS="${DB_PASS:-${TF_VAR_db_password:-}}"

# Last resort — prompt
if [ -z "$DB_PASS" ]; then
  read -rsp "🔑 Enter db_password (from terraform.tfvars): " DB_PASS
  echo
fi

if [ -z "$DB_PASS" ]; then
  echo "❌ db_password is required. Add it to terraform.tfvars or set TF_VAR_db_password."
  exit 1
fi

# ── Wait for SSH ──────────────────────────────────────────────────────────────
echo "⏳ Waiting for SSH to be ready..."
for i in $(seq 1 30); do
  if $SSH -o BatchMode=yes ubuntu@"$APP_IP" 'exit' 2>/dev/null; then
    echo "   SSH is ready."
    break
  fi
  [ "$i" -eq 30 ] && echo "❌ SSH not available after 5 minutes." && exit 1
  echo "   Not ready yet, retrying in 10s... ($i/30)"
  sleep 10
done

# ── Install Docker + AWS CLI if not already present ──────────────────────────
echo "🐳 Ensuring Docker and AWS CLI are installed..."
$SSH ubuntu@"$APP_IP" 'bash -s' <<'REMOTE'
set -e
if ! command -v docker &>/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y -qq
  sudo apt-get install -y -qq docker.io
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker ubuntu
fi
# Install Compose v2 plugin (replaces old docker-compose v1)
if ! sudo docker compose version &>/dev/null 2>&1; then
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -fsSL https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi
if ! command -v aws &>/dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  sudo apt-get install -y -qq unzip
  unzip -q /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
fi
REMOTE

# ── Prepare app directory and write .env ─────────────────────────────────────
echo "📝 Writing .env to server..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
APP_KEY="base64:$(openssl rand -base64 32)"

$SSH ubuntu@"$APP_IP" "sudo mkdir -p /opt/restaurant && sudo chown ubuntu:ubuntu /opt/restaurant"
$SSH ubuntu@"$APP_IP" "cat > /opt/restaurant/.env" <<ENV
AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
AWS_REGION=$AWS_REGION
APP_URL=http://$APP_IP
APP_KEY=$APP_KEY
DB_HOST=$DB_IP
DB_PORT=3306
DB_DATABASE=$DB_NAME
DB_USERNAME=$DB_USER
DB_PASSWORD=$DB_PASS
REVERB_APP_ID=restaurant-pos
REVERB_APP_KEY=restaurant-pos-key
REVERB_APP_SECRET=restaurant-pos-secret
ENV

# ── Copy docker-compose.prod.yml ──────────────────────────────────────────────
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ Cannot find docker-compose.prod.yml at: $COMPOSE_FILE"
  echo "   Set REPO_DIR=/path/to/restaurant-pos-poc and retry."
  exit 1
fi

echo "📋 Copying docker-compose.prod.yml and nginx config..."
$SCP "$COMPOSE_FILE" ubuntu@"$APP_IP":/opt/restaurant/docker-compose.prod.yml
$SSH ubuntu@"$APP_IP" "mkdir -p /opt/restaurant/docker/nginx"
$SCP "$REPO_DIR/docker/nginx/default.conf" ubuntu@"$APP_IP":/opt/restaurant/docker/nginx/default.conf

# ── ECR login + pull + up ─────────────────────────────────────────────────────
echo "🚢 Pulling images from ECR and starting containers..."

# Get ECR auth token locally (local machine has AWS credentials)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

$SSH ubuntu@"$APP_IP" "bash -s" <<REMOTE
set -e
echo "$ECR_PASSWORD" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"
sudo docker compose -f /opt/restaurant/docker-compose.prod.yml --env-file /opt/restaurant/.env pull
sudo docker compose -f /opt/restaurant/docker-compose.prod.yml --env-file /opt/restaurant/.env up -d

echo "⏳ Waiting for backend to be ready..."
sleep 10

# Re-cache config with the current APP_URL (IP changes on every redeploy)
sudo docker exec -u www-data restaurant-pos-backend-prod php artisan config:clear
sudo docker exec -u www-data restaurant-pos-backend-prod php artisan config:cache

sudo docker exec -u www-data restaurant-pos-backend-prod php artisan migrate --force

# Publish Filament CSS/JS to public/ so nginx can serve them as static files
sudo docker exec -u www-data restaurant-pos-backend-prod php artisan filament:assets

# Only seed on a fresh database (no users yet)
USER_COUNT=\$(sudo docker exec -u www-data restaurant-pos-backend-prod php artisan tinker --execute="echo \App\Models\User::count();" 2>/dev/null | grep -E '^[0-9]+$' | head -1)
if [ "\$USER_COUNT" = "0" ] || [ -z "\$USER_COUNT" ]; then
  echo "🌱 Fresh database detected — running seeders..."
  sudo docker exec -u www-data restaurant-pos-backend-prod php artisan db:seed --force
else
  echo "⏭️  Database already seeded (\$USER_COUNT users) — skipping."
fi
REMOTE

echo ""
echo "=============================="
echo "✅ Deploy complete!"
echo "   App:       http://$APP_IP"
echo "   WebSocket: ws://$APP_IP:8080"
echo "=============================="

