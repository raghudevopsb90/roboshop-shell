#!/bin/bash

# ============================================================
# Payment Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="payment"
SERVICE_PORT="8005"
APP_DIR="/home/roboshop/payment"
AMQP_HOST="${RABBITMQ_HOST}"
AMQP_USER="${RABBITMQ_USER}"
AMQP_PASS="${RABBITMQ_PASSWORD}"
CART_URL="http://${CART_HOST}:${PORT_CART}"
USER_URL="http://${USER_HOST}:${PORT_USER}"
REPO_URL="https://raw.githubusercontent.com/raghudevopsb89/roboshop-microservices/main/artifacts"

print_header "Payment Service Setup"

echo -e "\\e[36mCreating roboshop user\\e[0m"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mInstalling Python 3\\e[0m"
dnf install -y python3 python3-pip &>>$LOG_FILE
echo $?

echo -e "\\e[36mDownloading payment service\\e[0m"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -L -o /tmp/payment.zip "${REPO_URL}/payment.zip" &>>$LOG_FILE
echo $?

echo -e "\\e[36mExtracting payment service\\e[0m"
unzip -o /tmp/payment.zip &>>$LOG_FILE
echo $?

echo -e "\\e[36mInstalling Python dependencies\\e[0m"
pip3 install -r requirements.txt &>>$LOG_FILE
echo $?

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mCreating run script\\e[0m"
cat > /home/roboshop/run_payment.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export AMQP_HOST="${AMQP_HOST}"
export AMQP_USER="${AMQP_USER}"
export AMQP_PASS="${AMQP_PASS}"
export CART_URL="${CART_URL}"
export USER_URL="${USER_URL}"
export PORT="${SERVICE_PORT}"
exec /usr/local/bin/uvicorn main:app --host 0.0.0.0 --port ${SERVICE_PORT}
EOF
chmod +x /home/roboshop/run_payment.sh

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service_python "${SERVICE_NAME}" "main:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
