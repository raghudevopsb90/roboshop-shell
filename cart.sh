#!/bin/bash

# ============================================================
# Cart Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="cart"
SERVICE_PORT="8003"
APP_DIR="/home/roboshop/cart"
REDIS_HOST="${VALKEY_HOST}"
CATALOGUE_URL="http://${CATALOGUE_HOST}:${PORT_CATALOGUE}"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Cart Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Node.js 20\\e[0m"
curl -sL https://rpm.nodesource.com/setup_20.x | bash - &>>$LOG_FILE
dnf install -y nodejs &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading cart service\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/cart.zip "${REPO_URL}/cart.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting cart service\\e[0m"
unzip -o /tmp/cart.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling npm dependencies\\e[0m"
npm install --production &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mCreating run script\\e[0m"
cat > /home/roboshop/run_cart.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export REDIS_HOST="${REDIS_HOST}"
export CATALOGUE_URL="${CATALOGUE_URL}"
export PORT="${SERVICE_PORT}"
exec /usr/bin/node server.js
EOF
chmod +x /home/roboshop/run_cart.sh

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_cart.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
