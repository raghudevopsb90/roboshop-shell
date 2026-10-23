#!/bin/bash

# ============================================================
# Catalogue Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="catalogue"
SERVICE_PORT="8002"
APP_DIR="/app"
DB_HOST="${MYSQL_HOST}"
DB_NAME="catalogue"
DB_USER="catalogue"
DB_PASSWORD="RoboShop@1"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Catalogue Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling dependencies\\e[0m"
dnf install -y git go mysql8.4 &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading catalogue application\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/catalogue.zip "${REPO_URL}/catalogue.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting catalogue application\\e[0m"
unzip -o /tmp/catalogue.zip -d "$APP_DIR" &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting up database\\e[0m"
mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
" &>>$LOG_FILE
echo $?

echo -e "\\e[36mBuilding catalogue service\\e[0m"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

go mod tidy &>>$LOG_FILE
export CGO_ENABLED=0
go build -o "${APP_DIR}/catalogue" . &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" "appuser" || { print_footer 1 $SERVICE_NAME; exit 1; }
chmod o-rwx "${APP_DIR}" -R 2>/dev/null || { print_info "chmod completed"; }

echo -e "\\e[36mConfiguring and starting service\\e[0m"
cat > /etc/systemd/system/catalogue.service << EOF
[Unit]
Description=RoboShop Catalogue Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/catalogue
Restart=on-failure
RestartSec=10
SyslogIdentifier=catalogue

Environment=MYSQL_HOST=${DB_HOST}
Environment=MYSQL_USER=${DB_USER}
Environment=MYSQL_PASSWORD=${DB_PASSWORD}
Environment=MYSQL_DATABASE=${DB_NAME}
Environment=PORT=${SERVICE_PORT}

[Install]
WantedBy=multi-user.target
EOF
echo $?

start_service "catalogue" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
