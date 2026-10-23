#!/bin/bash

# ============================================================
# Notification Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="notification"
SERVICE_PORT="8008"
APP_DIR="/home/roboshop/notification"
BREVO_API_KEY=""
FROM_EMAIL="noreply@roboshop.demo"
FROM_NAME="RoboShop"
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "Notification Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Python
print_info "Step 2: Installing Python 3"
if ! command -v python3 &>/dev/null; then
    install_packages python3 python3-pip || { print_footer 1 $SERVICE_NAME; exit 1; }
else
    print_info "Python 3 already installed"
    python3 --version
fi

# Step 3: Download and install application
print_info "Step 3: Downloading notification service"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/notification.zip" -o /tmp/notification.zip 2>/dev/null
if [ -f /tmp/notification.zip ]; then
    unzip -o /tmp/notification.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/notification.zip
fi

# Install Python dependencies
print_info "Installing Python dependencies"
pip3 install -r requirements.txt 2>/dev/null || { print_info "pip install completed or failed"; }

# Step 4: Set permissions
print_info "Step 4: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 5: Create run script
print_info "Step 5: Creating run script"
cat > /home/roboshop/run_notification.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export BREVO_API_KEY="${BREVO_API_KEY}"
export FROM_EMAIL="${FROM_EMAIL}"
export FROM_NAME="${FROM_NAME}"
export PORT="${SERVICE_PORT}"
exec /usr/local/bin/gunicorn -b 0.0.0.0:${SERVICE_PORT} app:app
EOF
chmod +x /home/roboshop/run_notification.sh

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service_gunicorn "${SERVICE_NAME}" "app:app" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
