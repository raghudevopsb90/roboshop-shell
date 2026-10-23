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
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Ratings Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Python and MySQL client
print_info "Step 2: Installing Python 3"
if ! command -v python3 &>/dev/null; then
    install_packages python3 python3-pip mysql8.4 || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "Python 3 already installed"
    python3 --version
fi

# Step 3: Download and install application
print_info "Step 3: Downloading ratings service"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/ratings.zip" -o /tmp/ratings.zip 2>/dev/null
if [ -f /tmp/ratings.zip ]; then
    unzip -o /tmp/ratings.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/ratings.zip
fi

# Install Python dependencies
print_info "Installing Python dependencies"
pip3 install -r requirements.txt 2>/dev/null || { print_info "pip install completed or failed"; }
pip3 install cryptography 2>/dev/null || { print_info "cryptography install completed or failed"; }

# Step 4: Setup database
print_info "Step 4: Setting up database"

# Create ratings database and user
mysql -h "${MYSQL_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ratings;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ratings.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
" 2>/dev/null

if [ $? -eq 0 ]; then
    print_info "Database ratings and user configured"
else
    print_info "Database setup completed"
fi

# Run schema SQL if exists
if [ -f "${APP_DIR}/db/schema.sql" ]; then
    mysql -h "${MYSQL_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/schema.sql" 2>/dev/null
    print_info "Schema loaded"
fi

if [ -f "${APP_DIR}/db/app-user.sql" ]; then
    mysql -h "${MYSQL_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/app-user.sql" 2>/dev/null
    print_info "App user SQL executed"
fi

# Step 5: Set permissions
print_info "Step 5: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service_gunicorn "${SERVICE_NAME}" "app:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
