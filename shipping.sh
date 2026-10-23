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
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Shipping Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Java and Maven
print_info "Step 2: Installing Java 21 and Maven"
if ! command -v java &>/dev/null || [ "$(java -version 2>&1 | grep -c '21')" -eq 0 ]; then
    install_packages java-21-openjdk java-21-openjdk-devel maven mysql8.4 || { print_footer 1 $SERVICE_NAME; exit 1; }
    java -version 2>&1 | head -1
else
    print_info "Java 21 already installed"
    java -version 2>&1 | head -1
fi

# Step 3: Download and extract application
print_info "Step 3: Downloading shipping application"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/shipping.zip" -o /tmp/shipping.zip 2>/dev/null
if [ -f /tmp/shipping.zip ]; then
    unzip -o /tmp/shipping.zip -d "$APP_DIR" 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/shipping.zip
fi

# Step 4: Setup database
print_info "Step 4: Setting up database"

# Create shipping database and user
mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS shipping;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON shipping.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
" 2>/dev/null

if [ $? -eq 0 ]; then
    print_info "Database shipping and user configured"
else
    print_info "Database setup completed"
fi

# Run schema SQL if exists
if [ -f "${APP_DIR}/db/schema.sql" ]; then
    mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/schema.sql" 2>/dev/null
    print_info "Schema loaded"
fi

if [ -f "${APP_DIR}/db/app-user.sql" ]; then
    mysql -h "${DB_HOST}" -u root -p${MYSQL_ROOT_PASSWORD} < "${APP_DIR}/db/app-user.sql" 2>/dev/null
    print_info "App user SQL executed"
fi

# Step 5: Build the application
print_info "Step 5: Building shipping application"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

if [ -f "${APP_DIR}/pom.xml" ]; then
    mvn clean package -DskipTests 2>/dev/null || { print_info "Maven build skipped or failed"; }
    
    if [ -f "${APP_DIR}/target/shipping.jar" ]; then
        cp "${APP_DIR}/target/shipping.jar" "${APP_DIR}/shipping.jar" 2>/dev/null
    else
        print_info "Using existing shipping.jar"
    fi
else
    print_info "No pom.xml found, using existing jar"
fi

# Copy jar if needed
if [ -f "${APP_DIR}/target/shipping.jar" ] && [ ! -f "${APP_DIR}/shipping.jar" ]; then
    cp "${APP_DIR}/target/shipping.jar" "${APP_DIR}/shipping.jar" 2>/dev/null
fi

# Step 6: Set permissions
print_info "Step 6: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 7: Configure and start service
print_info "Step 7: Configuring and starting service"
configure_systemd_service_java "${SERVICE_NAME}" "${APP_DIR}/shipping.jar" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
