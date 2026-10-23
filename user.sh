#!/bin/bash

# ============================================================
# User Microservice Script
# ============================================================

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Variables specific to this service
SERVICE_NAME="user"
SERVICE_PORT="8001"
APP_DIR="/home/roboshop/user"
MONGODB_HOST="${MONGODB_HOST}"
JWT_SECRET="roboshop-secret-key"
REPO_URL="https://github.com/raghudevopsb89/roboshop-microservices/raw/main/artifacts"

print_header "User Service Setup"

# Step 1: Create roboshop user
print_info "Step 1: Creating roboshop user"
create_user || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 2: Install Node.js
print_info "Step 2: Installing Node.js 20"
install_nodejs || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 3: Download and install application
print_info "Step 3: Downloading user service"
mkdir -p "$APP_DIR"
cd "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

curl -sL "${REPO_URL}/user.zip" -o /tmp/user.zip 2>/dev/null
if [ -f /tmp/user.zip ]; then
    unzip -o /tmp/user.zip 2>/dev/null || { print_info "Failed to extract, using existing files"; }
    rm -f /tmp/user.zip
fi

# Install npm dependencies
print_info "Installing npm dependencies"
npm install --production 2>/dev/null || { print_info "npm install completed or failed"; }

# Step 4: Set permissions
print_info "Step 4: Setting permissions"
set_permissions "$APP_DIR" || { print_footer 1 $SERVICE_NAME; exit 1; }

# Step 5: Create run script
print_info "Step 5: Creating run script"
cat > /home/roboshop/run_user.sh << EOF
#!/bin/bash
cd ${APP_DIR} || exit 1
export MONGO_URL="mongodb://${MONGODB_HOST}:27017/users"
export JWT_SECRET="${JWT_SECRET}"
export PORT="${SERVICE_PORT}"
exec /usr/bin/node server.js
EOF
chmod +x /home/roboshop/run_user.sh

# Step 6: Configure and start service
print_info "Step 6: Configuring and starting service"
configure_systemd_service "${SERVICE_NAME}" "/bin/bash /home/roboshop/run_user.sh" "${SERVICE_PORT}" || { print_footer 1 $SERVICE_NAME; exit 1; }

start_service "${SERVICE_NAME}" || { print_footer 1 $SERVICE_NAME; exit 1; }

print_footer 0 $SERVICE_NAME
