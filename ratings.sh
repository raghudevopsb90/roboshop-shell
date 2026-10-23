#!/bin/bash

# ============================================================
# Ratings Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="ratings"
SERVICE_PORT="8006"
APP_DIR="/home/roboshop/ratings"
MYSQL_HOST="${MYSQL_HOST}"
MYSQL_USER="ratings"
MYSQL_PASSWORD="RoboShop@1"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Ratings Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Python 3\\e[0m"
dnf install -y python3 python3-pip mysql8.4 &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading ratings service\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/ratings.zip "${REPO_URL}/ratings.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting ratings service\\e[0m"
unzip -o /tmp/ratings.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling Python dependencies\\e[0m"
pip3 install -r requirements.txt &>>$LOG_FILE
pip3 install cryptography &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting up database\\e[0m"
mysql -h "${MYSQL_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ratings;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ratings.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
" &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service_gunicorn "${SERVICE_NAME}" "app:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
