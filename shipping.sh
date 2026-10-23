#!/bin/bash

# ============================================================
# Shipping Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="shipping"
SERVICE_PORT="8004"
APP_DIR="/home/roboshop/shipping"
DB_HOST="${MYSQL_HOST}"
DB_USER="shipping"
DB_PASSWORD="RoboShop@1"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Shipping Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Java 21 and Maven\\e[0m"
dnf install -y java-21-openjdk java-21-openjdk-devel maven mysql8.4 &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading shipping application\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/shipping.zip "${REPO_URL}/shipping.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting shipping application\\e[0m"
unzip -o /tmp/shipping.zip -d "$APP_DIR" &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting up database\\e[0m"
mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS shipping;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON shipping.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
" &>>$LOG_FILE
echo $?

echo -e "\\e[36mBuilding shipping application\\e[0m"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

if [ -f "${APP_DIR}/pom.xml" ]; then
    mvn clean package -DskipTests &>>$LOG_FILE
    if [ -f "${APP_DIR}/target/shipping.jar" ]; then
        cp "${APP_DIR}/target/shipping.jar" "${APP_DIR}/shipping.jar" 2>/dev/null
    fi
fi
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service_java "${SERVICE_NAME}" "${APP_DIR}/shipping.jar" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
