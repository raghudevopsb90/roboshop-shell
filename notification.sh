#!/bin/bash

# ============================================================
# Notification Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="notification"
SERVICE_PORT="8008"
APP_DIR="/app"
BREVO_API_KEY=""
FROM_EMAIL="noreply@roboshop.demo"
FROM_NAME="RoboShop"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Notification Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mCreating appuser\\e[0m"
create_appuser || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Python 3\\e[0m"
dnf install -y python3 python3-pip &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading notification service\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/notification.zip "${REPO_URL}/notification.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting notification service\\e[0m"
unzip -o /tmp/notification.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling Python dependencies\\e[0m"
pip3 install -r requirements.txt &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
chown -R appuser:appuser "${APP_DIR}" &>>$LOG_FILE
chmod o-rwx "${APP_DIR}" -R &>>$LOG_FILE
echo $?

echo -e "\\e[36mConfiguring and starting service\\e[0m"
cat > /etc/systemd/system/notification.service << EOF
[Unit]
Description=RoboShop Notification Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=${APP_DIR}
ExecStart=/usr/local/bin/gunicorn -b 0.0.0.0:${SERVICE_PORT} app:app
Restart=on-failure
RestartSec=10
SyslogIdentifier=notification

Environment=BREVO_API_KEY=${BREVO_API_KEY}
Environment=FROM_EMAIL=${FROM_EMAIL}
Environment=FROM_NAME=${FROM_NAME}
Environment=PORT=${SERVICE_PORT}

[Install]
WantedBy=multi-user.target
EOF
echo $?

start_service "notification" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
