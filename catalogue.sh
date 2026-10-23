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
APP_DIR="/home/roboshop/catalogue"
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

export CGO_ENABLED=0
go mod tidy &>>$LOG_FILE
go build -o "${APP_DIR}/service" ./... &>>$LOG_FILE
echo $?

echo -e "\\e[36mCreating run script\\e[0m"
cat > /home/roboshop/run_catalogue.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export MYSQL_HOST="${DB_HOST}"
export MYSQL_USER="${DB_USER}"
export MYSQL_PASSWORD="${DB_PASSWORD}"
export MYSQL_DATABASE="${DB_NAME}"
export PORT="${SERVICE_PORT}"
exec ${APP_DIR}/service
EOF
chmod +x /home/roboshop/run_catalogue.sh

echo -e "\\e[36mSetting permissions\\e[0m"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

echo -e "\\e[36mConfiguring and starting service\\e[0m"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_catalogue.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
