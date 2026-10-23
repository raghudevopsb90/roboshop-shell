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
APP_DIR="/app"
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

echo -e "\\e[36mCreating appuser\\e[0m"
create_appuser || { print_footer 1 $SERVICE_NAME; exit 1; }

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
chown -R appuser:appuser "${APP_DIR}" &>>$LOG_FILE
chmod o-rwx "${APP_DIR}" -R &>>$LOG_FILE
echo $?

echo -e "\\e[36mConfiguring and starting service\\e[0m"
cat > /etc/systemd/system/orders.service << EOF
[Unit]
Description=RoboShop Orders Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/java -jar ${APP_DIR}/orders.jar
Restart=on-failure
RestartSec=10
SyslogIdentifier=orders

Environment=MONGO_URL=${MONGO_URL}
Environment=AMQP_HOST=${AMQP_HOST}
Environment=AMQP_USER=${AMQP_USER}
Environment=AMQP_PASS=${AMQP_PASS}
Environment=SHIPPING_URL=${SHIPPING_URL}
Environment=NOTIFICATION_URL=${NOTIFICATION_URL}
Environment=PORT=${SERVICE_PORT}

[Install]
WantedBy=multi-user.target
EOF
echo $?

start_service "orders" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
