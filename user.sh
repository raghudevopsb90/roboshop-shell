#!/bin/bash

# ============================================================
# User Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="user"
SERVICE_PORT="8001"
APP_DIR="/home/roboshop/user"
MONGODB_HOST="${MONGODB_HOST}"
JWT_SECRET="roboshop-secret-key"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "User Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Node.js 20\\e[0m"
curl -sL https://rpm.nodesource.com/setup_20.x | bash - &>>$LOG_FILE
dnf install -y nodejs &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading user service\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/user.zip "${REPO_URL}/user.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting user service\\e[0m"
unzip -o /tmp/user.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling npm dependencies\\e[0m"
npm install --production &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mCreating run script\\e[0m"
cat > /home/roboshop/run_user.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export MONGO_URL="mongodb://${MONGODB_HOST}:27017/users"
export JWT_SECRET="${JWT_SECRET}"
export PORT="${SERVICE_PORT}"
exec /usr/bin/node server.js
EOF
chmod +x /home/roboshop/run_user.sh

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_user.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
