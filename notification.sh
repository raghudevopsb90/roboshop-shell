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
APP_DIR="/home/roboshop/notification"
BREVO_API_KEY=""
FROM_EMAIL="noreply@roboshop.demo"
FROM_NAME="RoboShop"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Notification Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

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
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mCreating run script\\e[0m"
cat > /home/roboshop/run_notification.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export BREVO_API_KEY="${BREVO_API_KEY}"
export FROM_EMAIL="${FROM_EMAIL}"
export FROM_NAME="${FROM_NAME}"
export PORT="${SERVICE_PORT}"
exec /usr/local/bin/gunicorn -b 0.0.0.0:${SERVICE_PORT} app:app
EOF
chmod +x /home/roboshop/run_notification.sh

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service_gunicorn "${SERVICE_NAME}" "app:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
