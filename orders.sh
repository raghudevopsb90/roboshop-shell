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
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Orders Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Java
print_info "Step 2: Installing Java 21"
if ! command -v java &>/dev/null || [ "$(java -version 2>&1 | grep -c '21')" -eq 0 ]; then
    install_packages java-21-openjdk java-21-openjdk-devel maven || { print_footer 1 $SERVICE_NAME; exit 1; }
    java -version 2>&1 | head -1
else
    print_info "Java 21 already installed"
    java -version 2>&1 | head -1
fi

# Step 3: Download and build application
print_info "Step 3: Downloading orders application"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/orders.zip" -o /tmp/orders.zip 2>/dev/null
if [ -f /tmp/orders.zip ]; then
    unzip -o /tmp/orders.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/orders.zip
fi

# Step 4: Build the application
print_info "Step 4: Building orders application"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

if [ -f "${APP_DIR}/pom.xml" ]; then
    mvn clean package -DskipTests 2>/dev/null || { print_info "Maven build skipped or failed"; }
    
    if [ -f "${APP_DIR}/target/orders.jar" ]; then
        cp "${APP_DIR}/target/orders.jar" "${APP_DIR}/orders.jar" 2>/dev/null
    else
        print_info "Using existing orders.jar"
    fi
else
    print_info "No pom.xml found, using existing jar"
fi

# Copy jar if needed
if [ -f "${APP_DIR}/target/orders.jar" ] && [ ! -f "${APP_DIR}/orders.jar" ]; then
    cp "${APP_DIR}/target/orders.jar" "${APP_DIR}/orders.jar" 2>/dev/null
fi

# Step 5: Set permissions
print_info "Step 5: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service_java "${SERVICE_NAME}" "${APP_DIR}/orders.jar" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
