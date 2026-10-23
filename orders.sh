#!/bin/bash

# ============================================================
# Orders Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="orders"
SERVICE_PORT="8007"
APP_DIR="/home/roboshop/orders"
MONGO_URL="mongodb://${MONGODB_HOST}:27017/orders"
AMQP_HOST="${RABBITMQ_HOST}"
AMQP_USER="${RABBITMQ_USER}"
AMQP_PASS="${RABBITMQ_PASSWORD}"
SHIPPING_URL="http://${SHIPPING_HOST}:${PORT_SHIPPING}"
NOTIFICATION_URL="http://${NOTIFICATION_HOST}:${PORT_NOTIFICATION}"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Orders Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Java 21\\e[0m"
dnf install -y java-21-openjdk java-21-openjdk-devel maven &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading orders application\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/orders.zip "${REPO_URL}/orders.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting orders application\\e[0m"
unzip -o /tmp/orders.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mBuilding orders application\\e[0m"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

if [ -f "${APP_DIR}/pom.xml" ]; then
    mvn clean package -DskipTests &>>$LOG_FILE
    if [ -f "${APP_DIR}/target/orders.jar" ]; then
        cp "${APP_DIR}/target/orders.jar" "${APP_DIR}/orders.jar" 2>/dev/null
    fi
fi
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service_java "${SERVICE_NAME}" "${APP_DIR}/orders.jar" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
